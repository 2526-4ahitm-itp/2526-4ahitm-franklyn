use screen_capture::FrameResponse;
use tokio::sync::mpsc;
use tracing::debug;

use crate::screen_capture::RecordControlMessage;

pub mod ws;

#[cfg(any(env = "dev", target_os = "macos"))]
mod image_generator;

mod screen_capture;

pub fn debug() {
    dbg!(config::CONFIG.api_websocket_url);
}

#[tracing::instrument]
pub async fn start() {
    let (ctrl_tx, ctrl_rx) = mpsc::channel::<RecordControlMessage>(10);
    let (frame_tx, frame_rx) = mpsc::channel::<FrameResponse>(10);

    debug!("starting screen recording task");
    tokio::spawn(async move {
        screen_capture::start_screen_recording(ctrl_rx, frame_tx).await;
    });

    debug!("starting server connection");
    ws::connect_to_server_async(ctrl_tx, frame_rx).await;
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
