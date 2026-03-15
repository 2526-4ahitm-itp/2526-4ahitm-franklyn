use std::io::{Read, Write};
use std::net::TcpListener;
use std::sync::mpsc::{self, Receiver, Sender};
use std::thread;
use std::time::{Duration, Instant};

use openidconnect::OAuth2TokenResponse;
use openidconnect::core::{
    CoreAuthenticationFlow, CoreClient, CoreIdToken, CoreProviderMetadata, CoreTokenResponse,
};
use openidconnect::reqwest::http_client;
use openidconnect::{
    AuthorizationCode, ClientId, CsrfToken, IssuerUrl, Nonce, PkceCodeChallenge, RedirectUrl, Scope,
};
use serde::Deserialize;
use tracing::error;
use url::Url;

use crate::config::CONFIG;

const DEFAULT_TIMEOUT: Duration = Duration::from_secs(300);

#[derive(Debug)]
pub struct OidcTokens {
    pub access_token: String,
    pub id_token: String,
    pub refresh_token: Option<String>,
}

#[derive(Debug)]
pub enum OidcError {
    Timeout,
    BrowserOpenFailed,
    CallbackInvalid(String),
    DiscoveryFailed(String),
    TokenExchangeFailed(String),
    IdTokenValidationFailed(String),
    Io(String),
    Url(String),
}

impl std::fmt::Display for OidcError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OidcError::Timeout => write!(f, "timed out waiting for OIDC callback"),
            OidcError::BrowserOpenFailed => write!(f, "failed to open browser for OIDC login"),
            OidcError::CallbackInvalid(msg) => write!(f, "invalid OIDC callback: {msg}"),
            OidcError::DiscoveryFailed(msg) => write!(f, "OIDC discovery failed: {msg}"),
            OidcError::TokenExchangeFailed(msg) => write!(f, "token exchange failed: {msg}"),
            OidcError::IdTokenValidationFailed(msg) => {
                write!(f, "ID token validation failed: {msg}")
            }
            OidcError::Io(msg) => write!(f, "IO error: {msg}"),
            OidcError::Url(msg) => write!(f, "URL error: {msg}"),
        }
    }
}

impl std::error::Error for OidcError {}

#[derive(Debug, Deserialize)]
struct CallbackQuery {
    code: String,
    state: String,
}

pub fn authenticate(timeout: Option<Duration>) -> Result<OidcTokens, OidcError> {
    if tokio::runtime::Handle::try_current().is_ok() {
        let (tx, rx) = mpsc::channel();
        thread::spawn(move || {
            let result = authenticate_inner(timeout);
            let _ = tx.send(result);
        });
        return rx
            .recv()
            .unwrap_or_else(|_| Err(OidcError::CallbackInvalid("auth thread closed".into())));
    }

    authenticate_inner(timeout)
}

fn authenticate_inner(timeout: Option<Duration>) -> Result<OidcTokens, OidcError> {
    let timeout = timeout.unwrap_or(DEFAULT_TIMEOUT);
    let start = Instant::now();

    let (port, listener) = bind_free_port().map_err(|err| OidcError::Io(err.to_string()))?;
    let redirect_url = format!("http://127.0.0.1:{port}/callback");

    let issuer = format!("{}/realms/{}", CONFIG.oidc_url, CONFIG.oidc_realm);
    let issuer_url =
        IssuerUrl::new(issuer.clone()).map_err(|err| OidcError::Url(err.to_string()))?;
    let provider_metadata = CoreProviderMetadata::discover(&issuer_url, http_client)
        .map_err(|err| OidcError::DiscoveryFailed(err.to_string()))?;

    let client = CoreClient::from_provider_metadata(
        provider_metadata,
        ClientId::new(CONFIG.oidc_client_id.to_string()),
        None,
    )
    .set_redirect_uri(
        RedirectUrl::new(redirect_url.clone()).map_err(|err| OidcError::Url(err.to_string()))?,
    );

    let (pkce_challenge, pkce_verifier) = PkceCodeChallenge::new_random_sha256();

    let auth_request = client
        .authorize_url(
            CoreAuthenticationFlow::AuthorizationCode,
            CsrfToken::new_random,
            Nonce::new_random,
        )
        .set_pkce_challenge(pkce_challenge)
        .add_scope(Scope::new(CONFIG.oidc_scopes.to_string()));

    let (auth_url, csrf_token, nonce) = auth_request.url();

    if webbrowser::open(auth_url.as_str()).is_err() {
        return Err(OidcError::BrowserOpenFailed);
    }

    let (tx, rx) = mpsc::channel::<CallbackQuery>();
    spawn_callback_server(listener, tx);

    let remaining = timeout
        .checked_sub(start.elapsed())
        .unwrap_or(Duration::from_secs(0));
    let callback = recv_with_timeout(rx, remaining)?;

    if callback.state.as_str() != csrf_token.secret() {
        return Err(OidcError::CallbackInvalid("state mismatch".into()));
    }

    let token_response: CoreTokenResponse = client
        .exchange_code(AuthorizationCode::new(callback.code))
        .set_pkce_verifier(pkce_verifier)
        .request(http_client)
        .map_err(|err| OidcError::TokenExchangeFailed(err.to_string()))?;

    let id_token: &CoreIdToken = token_response
        .extra_fields()
        .id_token()
        .ok_or_else(|| OidcError::IdTokenValidationFailed("missing id_token".into()))?;

    let claims = id_token
        .claims(&client.id_token_verifier(), &nonce)
        .map_err(|err| OidcError::IdTokenValidationFailed(err.to_string()))?;

    if claims.issuer().url() != issuer_url.url() {
        return Err(OidcError::IdTokenValidationFailed("issuer mismatch".into()));
    }

    let access_token = token_response.access_token().secret().to_string();
    let id_token = id_token.to_string();
    let refresh_token = token_response
        .refresh_token()
        .map(|token| token.secret().to_string());

    Ok(OidcTokens {
        access_token,
        id_token,
        refresh_token,
    })
}

fn spawn_callback_server(listener: TcpListener, tx: Sender<CallbackQuery>) {
    thread::spawn(move || {
        if let Err(err) = handle_callback(listener, tx) {
            error!("callback server error: {}", err);
        }
    });
}

fn handle_callback(listener: TcpListener, tx: Sender<CallbackQuery>) -> Result<(), OidcError> {
    for stream in listener.incoming() {
        let mut stream = stream.map_err(|err| OidcError::Io(err.to_string()))?;
        let mut buffer = [0u8; 4096];
        let bytes_read = stream
            .read(&mut buffer)
            .map_err(|err| OidcError::Io(err.to_string()))?;
        if bytes_read == 0 {
            continue;
        }

        let request = String::from_utf8_lossy(&buffer[..bytes_read]);
        let request_line = request.lines().next().unwrap_or("");
        let path = request_line.split_whitespace().nth(1).unwrap_or("/");

        let url = Url::parse(&format!("http://localhost{path}"))
            .map_err(|err| OidcError::Url(err.to_string()))?;

        let query: CallbackQuery = serde_urlencoded::from_str(url.query().unwrap_or(""))
            .map_err(|err| OidcError::CallbackInvalid(err.to_string()))?;

        let response_body =
            "<html><body><h2>Login complete</h2><p>You can close this window.</p></body></html>";
        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\n\r\n{}",
            response_body.len(),
            response_body
        );

        stream
            .write_all(response.as_bytes())
            .map_err(|err| OidcError::Io(err.to_string()))?;

        let _ = tx.send(query);
        break;
    }

    Ok(())
}

fn bind_free_port() -> Result<(u16, TcpListener), std::io::Error> {
    loop {
        let listener = TcpListener::bind("127.0.0.1:0")?;
        let port = listener.local_addr()?.port();
        if port > 1024 {
            return Ok((port, listener));
        }
    }
}

fn recv_with_timeout(
    rx: Receiver<CallbackQuery>,
    timeout: Duration,
) -> Result<CallbackQuery, OidcError> {
    rx.recv_timeout(timeout).map_err(|err| match err {
        mpsc::RecvTimeoutError::Timeout => OidcError::Timeout,
        mpsc::RecvTimeoutError::Disconnected => {
            OidcError::CallbackInvalid("callback channel closed".into())
        }
    })
}
