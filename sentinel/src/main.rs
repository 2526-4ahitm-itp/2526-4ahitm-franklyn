use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process;

use anyhow::Result;
use chrono::Local;
use clap::Parser;
use franklyn_sentinel::Args;
use franklyn_sentinel::VERSION;
use franklyn_sentinel::config;
#[cfg(not(debug_assertions))]
use franklyn_sentinel::telemetry;
#[cfg(not(target_os = "windows"))]
use pager::Pager;
#[cfg(not(debug_assertions))]
use sentry::integrations::tracing::EventFilter;
use tracing::Level;
use tracing::dispatcher::with_default;
use tracing::error;
use tracing::info;
use tracing_appender::rolling::{RollingFileAppender, Rotation};
use tracing_subscriber::filter::Targets;
use tracing_subscriber::fmt::format::FmtSpan;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;

const PROJECT_LICENSE: &str = include_str!(concat!(env!("OUT_DIR"), "/PROJECT_LICENSE.txt"));
const THIRDPARTY_SHORT: &str = include_str!(concat!(env!("OUT_DIR"), "/THIRDPARTY_SHORT.txt"));
const THIRDPARTY_FULL: &str = include_str!(concat!(env!("OUT_DIR"), "/THIRDPARTY_FULL.txt"));

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    if args.licenses {
        print_licenses();
        process::exit(0);
    }

    if args.licenses_full {
        print_licenses_full();
        process::exit(0);
    }

    if args.version {
        println!("Franklyn Sentinel v{VERSION}");
        process::exit(0);
    };

    #[cfg(not(debug_assertions))]
    let _sentry = config::CONFIG
        .telemetry
        .unwrap_or(true)
        .then(telemetry::init);

    let filter = match args.verbose {
        0 => Targets::new().with_target("franklyn_sentinel", Level::INFO),
        1 => Targets::new().with_target("franklyn_sentinel", Level::DEBUG),
        2 => Targets::new()
            .with_target("franklyn_sentinel", Level::TRACE)
            .with_default(Level::INFO),
        _ => Targets::new().with_default(Level::TRACE),
    };

    let filter = std::env::var("RUST_LOG")
        .ok()
        .and_then(|spec| spec.parse::<Targets>().ok())
        .unwrap_or(filter);

    let log_dir = get_log_dir();
    fs::create_dir_all(&log_dir).ok();

    let timestamp = Local::now().format("%Y%m%d_%H%M%S");
    let file_appender = RollingFileAppender::new(
        Rotation::HOURLY,
        &log_dir,
        format!("sentinel_{}.log", timestamp),
    );
    let (non_blocking, _guard) = tracing_appender::non_blocking(file_appender);

    let file_layer = tracing_subscriber::fmt::layer()
        .compact()
        .with_file(true)
        .with_line_number(true)
        .with_thread_ids(true)
        .with_target(false)
        .with_writer(non_blocking);

    let stdout_layer = tracing_subscriber::fmt::layer()
        .compact()
        .with_file(true)
        .with_line_number(true)
        .with_thread_ids(true)
        .with_target(false);

    #[cfg(not(debug_assertions))]
    {
        tracing_subscriber::registry()
            .with(filter)
            .with(file_layer)
            .with(stdout_layer)
            .with(
                sentry::integrations::tracing::layer().event_filter(|md| match *md.level() {
                    Level::ERROR => EventFilter::Event | EventFilter::Log,
                    _ => EventFilter::Log,
                }),
            )
            .init();
    }
    #[cfg(debug_assertions)]
    {
        tracing_subscriber::registry()
            .with(filter)
            .with(file_layer)
            .with(stdout_layer)
            .init();
    }

    info!("Initializing Franklyn Sentinel v{VERSION}");

    if let Some(cmd) = args.command {
        match cmd {
            franklyn_sentinel::Command::Config { action } => config::run(&action),
            franklyn_sentinel::Command::Join { pin } => {
                if let Err(err) = franklyn_sentinel::run(pin).await {
                    error!(
                        error = &*err as &dyn std::error::Error,
                        "sentinel stopped -- RESTART FRANKLYN!!!"
                    );
                    return Err(err);
                }
            }
        }
    }

    Ok(())
}

fn get_log_dir() -> PathBuf {
    try_log_dir().unwrap_or_else(get_user_log_dir)
}

fn flatpak_data_dir() -> Option<PathBuf> {
    if !Path::new("/.flatpak-info").exists() {
        return None;
    }
    std::env::var_os("XDG_DATA_HOME").map(PathBuf::from)
}

fn try_log_dir() -> Option<PathBuf> {
    if Path::new("/.flatpak-info").exists() {
        return None;
    }

    let log_dir = if cfg!(target_os = "windows") {
        std::env::var("PROGRAMDATA")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from(r"C:\ProgramData"))
            .join("franklyn-sentinel")
            .join("logs")
    } else if cfg!(target_os = "macos") {
        PathBuf::from("/Library/Logs/franklyn-sentinel")
    } else {
        PathBuf::from("/var/log/franklyn-sentinel")
    };

    std::fs::create_dir_all(&log_dir).ok()?;

    Some(log_dir)
}

fn get_user_log_dir() -> PathBuf {
    let log_dir = if cfg!(target_os = "macos") {
        if let Ok(home) = std::env::var("HOME") {
            PathBuf::from(home).join("Library/Logs/franklyn-sentinel")
        } else {
            std::env::temp_dir().join("franklyn-sentinel/logs")
        }
    } else if let Some(data_dir) = flatpak_data_dir() {
        data_dir.join("franklyn-sentinel/logs")
    } else if let Ok(home) = std::env::var("HOME") {
        PathBuf::from(home).join(".local/share/franklyn-sentinel/logs")
    } else {
        std::env::temp_dir().join("franklyn-sentinel/logs")
    };

    std::fs::create_dir_all(&log_dir).expect("failed to create log directory");

    log_dir
}

fn format_header() -> String {
    format!(
        "franklyn-sentinel v{VERSION}\n\n{PROJECT_LICENSE}\n{}",
        "=".repeat(80)
    )
}

fn print_licenses() {
    let bin = std::env::args()
        .next()
        .unwrap_or_else(|| "franklyn-sentinel".to_string());

    let content = format!(
        "{}\n{THIRDPARTY_SHORT}\nRun `{bin} --licenses-full` to read the complete license texts.\n",
        format_header()
    );

    page(&content);
}

fn print_licenses_full() {
    let content = format!("{}\n{THIRDPARTY_FULL}", format_header());
    page(&content);
}

fn page(content: &str) {
    #[cfg(not(target_os = "windows"))]
    {
        Pager::with_env("PAGER").setup();
    }
    print!("{content}");
}
