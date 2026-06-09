use clap::{ArgGroup, CommandFactory, FromArgMatches, Parser, Subcommand, ValueEnum};
use tracing::{error, info};

use crate::recorder::Recorder;

pub static VERSION: &str = env!("FRANKLYN_VERSION");

pub mod config;
pub mod oidc;
pub mod proto;
pub mod ws;

mod recorder;

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

pub fn debug() {
    dbg!(&config::CONFIG.api_url);
}

#[tracing::instrument(skip_all)]
pub async fn start(pin: u32) {
    let token = oidc::authenticate(Some(std::time::Duration::from_mins(1))).unwrap();

    info!("token acquired: {}...", &token.access_token.as_str()[..20]);

    let (recorder, capture_rx) = match Recorder::start().await {
        Ok(v) => v,
        Err(e) => {
            error!("failed to start recorder: {e}");
            return;
        }
    };

    ws::connect_to_server_async(recorder, capture_rx, token.access_token, pin).await;
}
