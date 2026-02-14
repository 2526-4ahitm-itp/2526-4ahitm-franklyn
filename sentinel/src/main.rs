use std::io;

use tracing::Level;

#[tokio::main]
async fn main() {
    let level = if cfg!(env = "dev") {
        Level::DEBUG
    } else {
        Level::WARN
    };

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
