use std::io::{self, Write as _};
use std::process::{self, Command, Stdio};

use clap::Parser;
use tracing::Level;

const PROJECT_LICENSE: &str = include_str!("../thirdparty/LICENSE");
const THIRDPARTY_SHORT: &str = include_str!("../thirdparty/licenses-short.txt");
const THIRDPARTY_FULL: &str = include_str!("../thirdparty/licenses-full.txt");

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Shows list of per-project licenses
    #[arg(long, conflicts_with = "licenses_full")]
    licenses: bool,

    /// Shows all projects with their licenses in a pager
    #[arg(long = "licenses-full", conflicts_with = "licenses")]
    licenses_full: bool,
}

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

    #[cfg(env = "dev")]
    let level = Level::DEBUG;

    #[cfg(env = "prod")]
    let level = Level::DEBUG;

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

/// Pipe `content` through the system pager. Falls back to stdout on failure.
fn page(content: &str) {
    let pager = std::env::var("PAGER").unwrap_or_default();
    let candidates: &[&str] = if pager.is_empty() {
        &["less", "more"]
    } else {
        // will try $PAGER first, then fall through to direct stdout
        &[]
    };

    // Try $PAGER first (if set), then the fallback candidates
    let attempts = if pager.is_empty() {
        candidates.to_vec()
    } else {
        let mut v = vec![pager.as_str()];
        v.extend_from_slice(candidates);
        v
    };

    for cmd in &attempts {
        // Split on whitespace to support e.g. PAGER="less -R"
        let parts: Vec<&str> = cmd.split_whitespace().collect();
        let (program, args) = match parts.split_first() {
            Some((p, a)) => (*p, a),
            None => continue,
        };

        let child = Command::new(program)
            .args(args)
            .stdin(Stdio::piped())
            .spawn();

        if let Ok(mut child) = child {
            if let Some(ref mut stdin) = child.stdin {
                // Ignore broken pipe — user may quit the pager early
                let _ = stdin.write_all(content.as_bytes());
            }
            drop(child.stdin.take());
            let _ = child.wait();
            return;
        }
    }

    // No pager available — write directly to stdout
    let stdout = io::stdout();
    let mut handle = stdout.lock();
    let _ = handle.write_all(content.as_bytes());
}
