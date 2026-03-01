use std::io;

use tracing::Level;

#[tokio::main]
async fn main() {
    #[cfg(env = "dev")]
    let leve = Level::DEBUG;

    #[cfg(env = "prod")]
    let leve = Level::DEBUG;

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
