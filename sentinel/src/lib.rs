use clap::{Parser, ValueEnum, arg};
use tracing::{error, info};

use crate::recorder::Recorder;

pub static VERSION: &str = env!("FRANKLYN_VERSION");

pub mod oidc;
pub mod ws;

mod recorder;

#[derive(Copy, Clone, Debug, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub enum Mode {
    Service,
    Gui,
}

#[derive(Parser, Debug, Clone)]
#[command(about, long_about = None)]
pub struct Args {
    /// Shows list of per-project licenses
    #[arg(long, conflicts_with = "licenses_full")]
    pub licenses: bool,

    /// Shows all projects with their licenses in a pager
    #[arg(long = "licenses-full", conflicts_with = "licenses")]
    pub licenses_full: bool,

    // Print version
    #[arg(long = "version", short)]
    pub version: bool,

    /// Run in service mode (used when started by systemd)
    #[arg(long = "mode", short, default_value = "gui")]
    pub mode: Mode,

    /// Run with extra logging
    #[arg(long = "verbose")]
    pub verbose: bool,
}

pub fn debug() {
    dbg!(config::CONFIG.api_url);
}

#[tracing::instrument(skip_all)]
pub async fn start(args: Args) {
    let token = oidc::authenticate(Some(std::time::Duration::from_mins(1))).unwrap();

    info!("token acquired: {}...", &token.access_token.as_str()[..20]);

    let (recorder, capture_rx) = match Recorder::start().await {
        Ok(v) => v,
        Err(e) => {
            error!("failed to start recorder: {e}");
            return;
        }
    };

    ws::connect_to_server_async(recorder, capture_rx, token.access_token).await;
}

mod config {
    use static_toml::static_toml;

    #[cfg(env = "dev")]
    static_toml! {
        pub(crate) static CONFIG = include_toml!("config/dev.toml");
    }

    #[cfg(env = "prod")]
    static_toml! {
        pub(crate) static CONFIG = include_toml!("config/prod.toml");
    }
}
