use std::io::{Read, Write};
use std::net::TcpListener;
use std::sync::mpsc::{self, Receiver, Sender};
use std::thread;
use std::time::{Duration, Instant};

use anyhow::{Context, bail};
use openidconnect::OAuth2TokenResponse;
use openidconnect::core::{
    CoreAuthenticationFlow, CoreClient, CoreIdToken, CoreProviderMetadata, CoreTokenResponse,
};
use openidconnect::reqwest::http_client;
use openidconnect::{
    AuthorizationCode, ClientId, CsrfToken, IssuerUrl, Nonce, PkceCodeChallenge, RedirectUrl, Scope,
};
use serde::Deserialize;
use tracing::{error, warn};
use url::Url;

use crate::config::CONFIG;

const DEFAULT_TIMEOUT: Duration = Duration::from_secs(300);

const TRUSTED_AUDIENCE: &str = "server";

#[derive(Debug)]
pub struct OidcTokens {
    pub access_token: String,
    pub id_token: String,
    pub refresh_token: Option<String>,
}

#[derive(Debug, Deserialize)]
struct CallbackQuery {
    code: String,
    state: String,
}

pub fn authenticate(timeout: Option<Duration>) -> anyhow::Result<OidcTokens> {
    if tokio::runtime::Handle::try_current().is_ok() {
        let (tx, rx) = mpsc::channel();
        thread::spawn(move || {
            let result = authenticate_inner(timeout);
            let _ = tx.send(result);
        });
        return rx.recv().context("auth thread closed")?;
    }

    authenticate_inner(timeout)
}

fn authenticate_inner(timeout: Option<Duration>) -> anyhow::Result<OidcTokens> {
    let timeout = timeout.unwrap_or(DEFAULT_TIMEOUT);
    let start = Instant::now();

    let (port, listener) = bind_free_port().context("IO error")?;
    let redirect_url = format!("http://127.0.0.1:{port}/callback");

    let issuer = format!("{}/realms/{}", CONFIG.oidc_url, CONFIG.oidc_realm);
    let issuer_url = IssuerUrl::new(issuer).context("URL error")?;
    let provider_metadata = CoreProviderMetadata::discover(&issuer_url, http_client)
        .with_context(|| format!("OIDC discovery failed for {}", issuer_url.url()))?;

    let client = CoreClient::from_provider_metadata(
        provider_metadata,
        ClientId::new(CONFIG.oidc_client_id.to_string()),
        None,
    )
    .set_redirect_uri(RedirectUrl::new(redirect_url).context("URL error")?);

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

    if let Err(err) = webbrowser::open(auth_url.as_str()) {
        warn!("failed to open browser for OIDC login: {err}");
        eprintln!("Could not open your browser automatically.");
    }
    eprintln!("To log in, open this URL in your browser:\n\n    {auth_url}\n");

    let (tx, rx) = mpsc::channel::<CallbackQuery>();
    spawn_callback_server(listener, tx);

    let remaining = timeout
        .checked_sub(start.elapsed())
        .unwrap_or(Duration::from_secs(0));
    let callback = recv_with_timeout(rx, remaining)?;

    if callback.state.as_str() != csrf_token.secret() {
        bail!("invalid OIDC callback: state mismatch");
    }

    let token_response: CoreTokenResponse = client
        .exchange_code(AuthorizationCode::new(callback.code))
        .set_pkce_verifier(pkce_verifier)
        .request(http_client)
        .context("token exchange failed")?;

    let id_token: &CoreIdToken = token_response
        .extra_fields()
        .id_token()
        .context("missing id_token")?;

    let claims = id_token
        .claims(
            &client
                .id_token_verifier()
                .set_other_audience_verifier_fn(|aud| **aud == TRUSTED_AUDIENCE),
            &nonce,
        )
        .context("ID token validation failed")?;

    if claims.issuer().url() != issuer_url.url() {
        bail!("ID token validation failed: issuer mismatch");
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

fn handle_callback(listener: TcpListener, tx: Sender<CallbackQuery>) -> anyhow::Result<()> {
    for stream in listener.incoming() {
        let mut stream = stream.context("IO error")?;
        let mut buffer = [0u8; 4096];
        let bytes_read = stream.read(&mut buffer).context("IO error")?;
        if bytes_read == 0 {
            continue;
        }

        let request = String::from_utf8_lossy(&buffer[..bytes_read]);
        let request_line = request.lines().next().unwrap_or("");
        let path = request_line.split_whitespace().nth(1).unwrap_or("/");

        let url = Url::parse(&format!("http://localhost{path}")).context("URL error")?;

        let query: CallbackQuery = serde_urlencoded::from_str(url.query().unwrap_or(""))
            .context("invalid OIDC callback")?;

        let response_body =
            "<html><body><h2>Login complete</h2><p>You can close this window.</p></body></html>";
        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\n\r\n{}",
            response_body.len(),
            response_body
        );

        stream.write_all(response.as_bytes()).context("IO error")?;

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
) -> anyhow::Result<CallbackQuery> {
    match rx.recv_timeout(timeout) {
        Ok(callback) => Ok(callback),
        Err(mpsc::RecvTimeoutError::Timeout) => bail!("timed out waiting for OIDC callback"),
        Err(mpsc::RecvTimeoutError::Disconnected) => {
            bail!("invalid OIDC callback: callback channel closed")
        }
    }
}
