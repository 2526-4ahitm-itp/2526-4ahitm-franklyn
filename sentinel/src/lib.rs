use clap::{ArgGroup, Parser, Subcommand};
use tokio::select;
use tokio_util::sync::CancellationToken;
use tracing::{error, info, warn};

use crate::recorder_v3::{JPegBase64, Recorder as RecorderV3, source::Source};

pub static VERSION: &str = env!("FRANKLYN_VERSION");

pub mod config;
pub mod oidc;
pub mod proto;
pub mod telemetry;
pub mod ws;

mod recorder_v3;

#[derive(Parser, Debug, Clone)]
#[command(about, long_about = None, arg_required_else_help = true)]
#[command(group = ArgGroup::new("exit_flags_group").args(&["licenses", "licenses_full", "version"]))]
pub struct Args {
    /// Shows list of per-project licenses
    #[arg(long)]
    pub licenses: bool,

    /// Shows all projects with their licenses in a pager
    #[arg(long)]
    pub licenses_full: bool,

    // Print version
    #[arg(long, short)]
    pub version: bool,

    /// Run with extra logging
    #[arg(long)]
    pub verbose: bool,

    /// command action
    #[command(subcommand)]
    pub command: Option<Command>,
}

#[derive(Clone, Debug, Subcommand)]
pub enum Command {
    /// Read and edit configuration
    Config {
        #[command(subcommand)]
        action: ConfigAction,
    },
    /// Join an exam
    Join { pin: u32 },
}

#[derive(Clone, Debug, Subcommand)]
pub enum ConfigAction {
    /// get a configuration value
    Get { key: String },

    /// set a configuration value
    Set { key: String, value: String },

    /// remove a configuration key from the configuration file and reset it to
    /// default
    Unset { key: String },

    /// list all configuration
    List,

    /// show the path of the configuration file
    Path,

    /// opens and editor with the configuration file
    Edit,
}

#[tracing::instrument(skip_all)]
pub async fn start(pin: u32) {
    let token = oidc::authenticate(Some(std::time::Duration::from_mins(1))).unwrap();

    info!("token acquired: {}...", &token.access_token.as_str()[..20]);

    let source = Source::make().await.expect("failed to make source");

    let (recorder, capture_rx, mut errors_rx) =
        RecorderV3::build::<JPegBase64>(source).expect("failed to acquire recorder");

    let cancel_token = CancellationToken::new();

    let ws_cancel_token = cancel_token.clone();

    let mut ws_task = tokio::spawn(async move {
        select! {
            _ = ws_cancel_token.cancelled() => {
                info!("cancelled, dropping websocket!");
            },
            _ = ws::connect_to_server_async(recorder, capture_rx, token.access_token, pin) => {},
        };
    });

    loop {
        select! {
            res = &mut ws_task => {
                if let Err(e) = res {
                    error!("websocket task panicked: {}", e);
                }
                error!("connection to server ended, RESTART FRANKLYN!!!");
                return;
            }

            Some(error) = errors_rx.recv() => match error {
                recorder_v3::RecorderError::BusEndOfStream => {
                    error!("End of capture, RESTART FRANKLYN!!!");
                    break;
                }
                recorder_v3::RecorderError::BusError(err_str) => {
                    error!("Bus error '{}', RESTART FRANKLYN!!!", err_str);
                    break;
                }
                recorder_v3::RecorderError::NoFrames(seconds) if seconds >= 60 => {
                    error!("No frames for {}s, RESTART FRANKLYN!!!", seconds);
                    break;
                }
                recorder_v3::RecorderError::NoFrames(seconds) => {
                    warn!("No frames coming: {}s", seconds);
                }
            },
        }
    }

    cancel_token.cancel();
    let _ = ws_task.await;
    std::process::exit(1)
}
