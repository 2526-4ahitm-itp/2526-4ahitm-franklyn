use ashpd::{
    desktop::{
        CreateSessionOptions, PersistMode,
        screencast::{CursorMode, Screencast, SelectSourcesOptions, SourceType},
    },
    enumflags2::BitFlags,
};
use tokio::sync::mpsc::{Receiver, channel};

pub struct CaptureConfig {
    pub fps: f32,
    pub max_dimension: u32,
    pub h264_profile: String,
    pub max_keyframe_interval_secs: u32,
    pub segment_interval_secs: u32,
}

pub enum CaptureOutput {
    Jpeg(Vec<u8>),
}

#[derive(Debug, thiserror::Error)]
pub enum CaptureError {
    #[error("GStreamer initialization failed: {0}")]
    GstreamerInit(String),

    #[error("XDG portal dialog was cancelled by the user")]
    PortalCancelled,

    #[error("XDG portal session failed: {0}")]
    PortalFailed(String),

    #[error("GStreamer pipeline creation failed: {0}")]
    PipelineFailed(String),

    #[error("No display server detected (need X11 or Wayland)")]
    NoDisplayServer,
}

pub struct Recorder {}

impl Recorder {
    pub async fn start(
        config: CaptureConfig,
    ) -> Result<(Self, Receiver<CaptureOutput>), CaptureError> {
        let proxy = Screencast::new().await.unwrap();

        let session = proxy
            .create_session(CreateSessionOptions::default())
            .await
            .unwrap();

        let req = proxy
            .select_sources(
                &session,
                SelectSourcesOptions::default()
                    .set_cursor_mode(CursorMode::Embedded)
                    .set_sources(BitFlags::from_flag(SourceType::Monitor))
                    .set_multiple(false)
                    .set_persist_mode(PersistMode::DoNot),
            )
            .await
            .unwrap();

        dbg!(&req);
        dbg!(&session);

        // if this fails, something is wrong like user didn't select anything, selected wrong type...
        let response = proxy
            .start(&session, None, Default::default())
            .await
            .unwrap()
            .response()
            .unwrap();
        
        dbg!(&response);

        let fd = proxy
            .open_pipe_wire_remote(&session, Default::default())
            .await
            .unwrap();
        let node_id = response.streams()[0].pipe_wire_node_id();


        let (tx, rx) = channel::<CaptureOutput>(10);

        Ok((Self {}, rx))
    }
}
