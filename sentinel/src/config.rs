use std::sync::LazyLock;

macro_rules! cfg_val {
    ($key:literal) => {
        std::env::var($key)
            .ok()
            .unwrap_or_else(|| env!($key).to_string())
    };
}

pub struct Config {
    pub api_url: String,
    pub oidc_url: String,
    pub oidc_realm: String,
    pub oidc_client_id: String,
    pub oidc_scopes: String,
}

pub static CONFIG: LazyLock<Config> = LazyLock::new(|| Config {
    api_url: cfg_val!("API_URL"),
    oidc_url: cfg_val!("OIDC_URL"),
    oidc_realm: cfg_val!("OIDC_REALM"),
    oidc_client_id: cfg_val!("OIDC_CLIENT_ID"),
    oidc_scopes: cfg_val!("OIDC_SCOPES"),
});
