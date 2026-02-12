use screen_capture::FrameResponse;
use tokio::sync::mpsc;
use xcap::Frame;

use crate::screen_capture::RecordControlMessage;

pub mod ws;

mod screen_capture;

pub fn debug() {
    dbg!(config::CONFIG.api_websocket_url);
}

pub async fn start() {
    let (ctrl_tx, mut ctrl_rx) = mpsc::channel::<RecordControlMessage>(10);
    let (frame_tx, mut frame_rx) = mpsc::channel::<FrameResponse>(10);

    tokio::spawn(async move {
        screen_capture::start_screen_recording(ctrl_rx, frame_tx).await;
    });

    ws::connect_to_server_sync(ctrl_tx, frame_rx).await;
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
