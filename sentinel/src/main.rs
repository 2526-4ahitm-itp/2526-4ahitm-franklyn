use std::fs;
use std::path::PathBuf;
use std::process;

use chrono::Local;
use clap::Parser;
use franklyn_sentinel::Args;
use franklyn_sentinel::VERSION;
use pager::Pager;
use tracing::Level;
use tracing::info;
use tracing_appender::rolling::{RollingFileAppender, Rotation};
use tracing_subscriber::fmt::format::FmtSpan;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;

const PROJECT_LICENSE: &str = include_str!("../thirdparty/LICENSE");
const THIRDPARTY_SHORT: &str = include_str!("../thirdparty/licenses-short.txt");
const THIRDPARTY_FULL: &str = include_str!("../thirdparty/licenses-full.txt");

#[tokio::main]
async fn main() {
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

    let level = Level::WARN;

    let filter = tracing_subscriber::filter::LevelFilter::from_level(level);

    let log_dir = get_log_dir();
    fs::create_dir_all(&log_dir).ok();

    let timestamp = Local::now().format("%Y%m%d_%H%M%S");
    let file_appender = RollingFileAppender::new(
        Rotation::NEVER,
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
        .with_writer(non_blocking)
        .with_span_events(FmtSpan::CLOSE);

    let stdout_layer = tracing_subscriber::fmt::layer()
        .compact()
        .with_file(true)
        .with_line_number(true)
        .with_thread_ids(true)
        .with_target(false)
        .with_span_events(FmtSpan::CLOSE);

    tracing_subscriber::registry()
        .with(filter)
        .with(file_layer)
        .with(stdout_layer)
        .init();

    info!("Initializing Franklyn Sentinel v{VERSION}");

    franklyn_sentinel::start(args).await;
}

fn get_log_dir() -> PathBuf {
    try_log_dir().unwrap_or_else(get_user_log_dir)
}

fn try_log_dir() -> Option<PathBuf> {
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
    let log_dir = if let Ok(home) = std::env::var("HOME") {
        PathBuf::from(home).join(".local/share/franklyn-sentinel/logs")
    } else {
        std::env::temp_dir().join("franklyn-sentinel/logs")
    };

    std::fs::create_dir_all(&log_dir).expect("failed to create log directory");

    log_dir
}

fn format_header() -> String {
    format!(
        "franklyn-sentinel v{}\n\n{PROJECT_LICENSE}\n{}",
        env!("CARGO_PKG_VERSION"),
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
    Pager::with_env("PAGER").setup();
    print!("{content}");
}
