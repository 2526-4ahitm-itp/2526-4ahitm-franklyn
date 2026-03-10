use std::io;
use std::process;
use std::sync::OnceLock;

use clap::Parser;
use pager::Pager;
use tracing::Level;

const PROJECT_LICENSE: &str = include_str!("../thirdparty/LICENSE");
const THIRDPARTY_SHORT: &str = include_str!("../thirdparty/licenses-short.txt");
const THIRDPARTY_FULL: &str = include_str!("../thirdparty/licenses-full.txt");

#[derive(Parser, Debug, Clone)]
#[command(version, about, long_about = None)]
struct Args {
    /// Shows list of per-project licenses
    #[arg(long, conflicts_with = "licenses_full")]
    licenses: bool,

    /// Shows all projects with their licenses in a pager
    #[arg(long = "licenses-full", conflicts_with = "licenses")]
    licenses_full: bool,

    /// Run in service mode (used when started by systemd)
    #[arg(long = "service")]
    service: bool,

    /// Run with extra logging
    #[arg(long = "verbose", short)]
    verbose: bool,
}

static ARGS: OnceLock<Args> = OnceLock::new();

#[tokio::main]
async fn main() {
    let args = Args::parse();

    ARGS.set(args.clone())
        .expect("Args already set which should not be possible");

    if args.licenses {
        print_licenses();
        process::exit(0);
    }

    if args.licenses_full {
        print_licenses_full();
        process::exit(0);
    }

    let level = Level::INFO;

    let subscriber = tracing_subscriber::fmt()
        .compact()
        .with_file(true)
        .with_line_number(true)
        .with_thread_ids(true)
        .with_target(false)
        .with_writer(io::stdout)
        .with_test_writer()
        .with_max_level(level)
        .finish();

    tracing::subscriber::set_global_default(subscriber).unwrap();

    franklyn_sentinel::start().await;
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
