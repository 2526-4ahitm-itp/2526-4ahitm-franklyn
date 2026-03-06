use std::io;
use std::process;

use tracing::Level;

const PROJECT_LICENSE: &str = include_str!("../thirdparty/LICENSE");
const THIRDPARTY_SHORT: &str = include_str!("../thirdparty/licenses-short.txt");
const THIRDPARTY_FULL: &str = include_str!("../thirdparty/licenses-full.txt");

#[tokio::main]
async fn main() {
    if std::env::args().any(|arg| arg == "--licenses-full") {
        print_licenses_full();
        process::exit(0);
    }

    if std::env::args().any(|arg| arg == "--licenses") {
        print_licenses();
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

fn print_header() {
    println!("franklyn-sentinel v{}\n", env!("CARGO_PKG_VERSION"));
    println!("{PROJECT_LICENSE}");
    println!("{}", "=".repeat(80));
}

fn print_licenses() {
    print_header();
    print!("{THIRDPARTY_SHORT}");
    let bin = std::env::args()
        .next()
        .unwrap_or_else(|| "franklyn-sentinel".to_string());
    println!("\nRun `{bin} --licenses-full` to read the complete license texts.");
}

fn print_licenses_full() {
    print_header();
    print!("{THIRDPARTY_FULL}");
}
