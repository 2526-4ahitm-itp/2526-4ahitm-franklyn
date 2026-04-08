use clap::{ArgGroup, CommandFactory, FromArgMatches, Parser, ValueEnum, arg};
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

static EXIT_FLAGS: &[&str] = &["version", "licenses", "licenses_full"];
static RUNTIME_FLAGS: &[&str] = &["pin", "verbose", "mode"];

#[derive(Parser, Debug, Clone)]
#[command(about, long_about = None)]
#[command(group = ArgGroup::new("exit_flags_group").args(EXIT_FLAGS))]
pub struct Args {
    /// Shows list of per-project licenses
    #[arg(long)]
    pub licenses: bool,

    /// Shows all projects with their licenses in a pager
    #[arg(long = "licenses-full")]
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

    /// 4-digit pin of the exam to join
    #[arg(long = "pin", short, required_unless_present_any = EXIT_FLAGS)]
    pub pin: Option<u32>,
}

impl Args {
    pub fn parse() -> Self {
        let mut cmd = Self::command();

        for &exit_flag in EXIT_FLAGS {
            cmd = cmd.mut_arg(exit_flag, |arg| arg.conflicts_with_all(RUNTIME_FLAGS));
        }

        Self::from_arg_matches(&cmd.get_matches()).unwrap_or_else(|e| e.exit())
    }
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

    // args.pin should never be None if the code is here
    ws::connect_to_server_async(
        recorder,
        capture_rx,
        token.access_token,
        args.pin
            .expect("Tried to get args.pin but was None. This should not happen"),
    )
    .await;
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
