use std::sync::LazyLock;

macro_rules! cfg_val {
    ($key:literal, $default:expr) => {
        std::env::var($key) // 3. runtime
            .ok()
            .or_else(|| option_env!($key).map(str::to_string)) // 2. build-time
            .unwrap_or_else(|| $default.to_string()) // 1. app default
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
    api_url: cfg_val!("API_URL", "//franklyn.htl-leonding.ac.at"),
    oidc_url: cfg_val!("OIDC_URL", "https://auth.htl-leonding.ac.at"),
    oidc_realm: cfg_val!("OIDC_REALM", "franklyn"),
    oidc_client_id: cfg_val!("OIDC_CLIENT_ID", "sentinel"),
    oidc_scopes: cfg_val!("OIDC_SCOPES", "openid"),
});
