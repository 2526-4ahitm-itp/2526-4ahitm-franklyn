use std::env;
use std::os::fd::AsRawFd;
use std::sync::{
    Arc,
    atomic::{AtomicBool, AtomicU32, Ordering},
};

use ashpd::{
    desktop::{
        CreateSessionOptions, PersistMode,
        screencast::{CursorMode, Screencast, SelectSourcesOptions, SourceType},
    },
    enumflags2::BitFlags,
};
use gstreamer as gst;
use gstreamer::prelude::*;
use gstreamer_app as gst_app;
use tokio::sync::mpsc::{Receiver, Sender, channel};

#[derive(Debug, Clone)]
pub struct JpegBlob {
    pub data: Vec<u8>,
    pub sequence: u64,
    pub is_keyframe: bool,
}

#[derive(Debug, Clone)]
pub enum CaptureOutput {
    Jpeg(JpegBlob),
}

#[derive(Debug, Clone)]
pub enum CaptureMode {
    Picker,
    NoPicker,
}

#[derive(Debug, Clone)]
pub struct CaptureConfig {
    pub fps: f32,
    pub max_dimension: u32,
    pub jpeg_quality: u8,
    pub mode: CaptureMode,
}

impl Default for CaptureConfig {
    fn default() -> Self {
        Self {
            fps: 5.0,
            max_dimension: 1920,
            jpeg_quality: 5,
            mode: CaptureMode::Picker,
        }
    }
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

    #[error("No streams returned by XDG portal screencast")]
    PortalNoStream,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Backend {
    X11,
    Wayland,
}

#[derive(Debug)]
struct PortalCapture {
    fd: std::os::fd::OwnedFd,
    node_id: u32,
}

pub struct Recorder {
    pipeline: gst::Pipeline,
    stop_flag: Arc<AtomicBool>,
    fps_milli: Arc<AtomicU32>,
    backend: Backend,
    fps_filter: gst::Element,
    _portal_capture: Option<PortalCapture>,
}

impl Recorder {
    pub async fn start(
        config: CaptureConfig,
    ) -> Result<(Self, Receiver<CaptureOutput>), CaptureError> {
        gst::init().map_err(|e| CaptureError::GstreamerInit(e.to_string()))?;

        let backend = detect_backend()?;
        let fps = config.fps.clamp(0.2, 5.0);
        let quality = config.jpeg_quality.clamp(1, 100);
        let max_dimension = config.max_dimension.max(1);

        let portal_capture = if matches!(config.mode, CaptureMode::Picker) {
            Some(start_portal_capture().await?)
        } else {
            None
        };

        let pipeline = build_pipeline(
            backend,
            fps,
            max_dimension,
            quality,
            portal_capture.as_ref(),
            matches!(config.mode, CaptureMode::Picker),
        )?;

        let appsink = pipeline
            .by_name("sink")
            .ok_or_else(|| CaptureError::PipelineFailed("appsink not found".to_string()))?
            .dynamic_cast::<gst_app::AppSink>()
            .map_err(|_| CaptureError::PipelineFailed("sink is not an appsink".to_string()))?;

        let fps_filter = pipeline
            .by_name("fps_filter")
            .ok_or_else(|| CaptureError::PipelineFailed("fps filter not found".to_string()))?;

        pipeline.set_state(gst::State::Playing).map_err(|e| {
            CaptureError::PipelineFailed(format!("failed to set playing state: {e:?}"))
        })?;

        let (tx, rx) = channel::<CaptureOutput>(4);
        let stop_flag = Arc::new(AtomicBool::new(false));
        let stop_flag_task = Arc::clone(&stop_flag);

        tokio::task::spawn_blocking(move || pull_jpegs(appsink, tx, stop_flag_task));

        Ok((
            Self {
                pipeline,
                stop_flag,
                fps_milli: Arc::new(AtomicU32::new((fps * 1000.0) as u32)),
                backend,
                fps_filter,
                _portal_capture: portal_capture,
            },
            rx,
        ))
    }

    pub fn set_fps(&self, fps: f32) {
        let fps = fps.clamp(0.2, 5.0);
        self.fps_milli
            .store((fps * 1000.0) as u32, Ordering::Relaxed);

        let (num, den) = fps_to_fraction(fps);
        let caps = gst::Caps::builder("video/x-raw")
            .field("framerate", gst::Fraction::new(num, den))
            .build();

        let _ = self.fps_filter.set_property("caps", &caps);

        self.force_keyframe();
    }

    pub fn force_keyframe(&self) {
        let _ = self.pipeline.send_event(gst::event::Reconfigure::new());
    }

    pub fn stop(&self) {
        self.stop_flag.store(true, Ordering::Relaxed);
        let _ = self.pipeline.set_state(gst::State::Null);
    }

    pub fn backend_name(&self) -> &'static str {
        match self.backend {
            Backend::X11 => "x11",
            Backend::Wayland => "wayland",
        }
    }
}

impl Drop for Recorder {
    fn drop(&mut self) {
        self.stop();
    }
}

fn pull_jpegs(appsink: gst_app::AppSink, tx: Sender<CaptureOutput>, stop_flag: Arc<AtomicBool>) {
    let mut sequence = 0u64;

    loop {
        if stop_flag.load(Ordering::Relaxed) {
            break;
        }

        let Some(sample) = appsink.try_pull_sample(gst::ClockTime::from_mseconds(500)) else {
            continue;
        };

        let Some(buffer) = sample.buffer() else {
            continue;
        };

        let Ok(map) = buffer.map_readable() else {
            continue;
        };

        let blob = JpegBlob {
            data: map.as_slice().to_vec(),
            sequence,
            is_keyframe: true,
        };

        if tx.try_send(CaptureOutput::Jpeg(blob)).is_ok() {
            sequence += 1;
        }
    }
}

fn detect_backend() -> Result<Backend, CaptureError> {
    if env::var("WAYLAND_DISPLAY").is_ok()
        || matches!(env::var("XDG_SESSION_TYPE").as_deref(), Ok("wayland"))
    {
        Ok(Backend::Wayland)
    } else if env::var("DISPLAY").is_ok() {
        Ok(Backend::X11)
    } else {
        Err(CaptureError::NoDisplayServer)
    }
}

async fn start_portal_capture() -> Result<PortalCapture, CaptureError> {
    let proxy = Screencast::new()
        .await
        .map_err(|e| CaptureError::PortalFailed(e.to_string()))?;

    let session = proxy
        .create_session(CreateSessionOptions::default())
        .await
        .map_err(|e| CaptureError::PortalFailed(e.to_string()))?;

    proxy
        .select_sources(
            &session,
            SelectSourcesOptions::default()
                .set_cursor_mode(CursorMode::Embedded)
                .set_sources(BitFlags::from_flag(SourceType::Monitor))
                .set_multiple(false)
                .set_persist_mode(PersistMode::DoNot),
        )
        .await
        .map_err(|e| CaptureError::PortalFailed(e.to_string()))?;

    let response = proxy
        .start(&session, None, Default::default())
        .await
        .map_err(|e| CaptureError::PortalFailed(e.to_string()))?
        .response()
        .map_err(|e| {
            let msg = e.to_string();
            if msg.to_ascii_lowercase().contains("cancel") {
                CaptureError::PortalCancelled
            } else {
                CaptureError::PortalFailed(msg)
            }
        })?;

    let stream = response
        .streams()
        .first()
        .ok_or(CaptureError::PortalNoStream)?;

    let fd = proxy
        .open_pipe_wire_remote(&session, Default::default())
        .await
        .map_err(|e| CaptureError::PortalFailed(e.to_string()))?;

    Ok(PortalCapture {
        fd,
        node_id: stream.pipe_wire_node_id(),
    })
}

fn build_pipeline(
    backend: Backend,
    fps: f32,
    max_dimension: u32,
    jpeg_quality: u8,
    portal_capture: Option<&PortalCapture>,
    picker_mode: bool,
) -> Result<gst::Pipeline, CaptureError> {
    let (fps_num, fps_den) = fps_to_fraction(fps);

    let source = if picker_mode {
        let capture = portal_capture.ok_or_else(|| {
            CaptureError::PipelineFailed("picker mode selected without portal capture".to_string())
        })?;

        format!(
            "pipewiresrc fd={} path={} do-timestamp=true always-copy=true",
            capture.fd.as_raw_fd(),
            capture.node_id
        )
    } else {
        match backend {
            Backend::X11 => "ximagesrc use-damage=false".to_string(),
            Backend::Wayland => "pipewiresrc do-timestamp=true always-copy=true".to_string(),
        }
    };

    let target_h = max_dimension.max(1);
    let target_w = ((target_h as u64) * 16 / 9) as u32;

    let pipeline_str = format!(
        "{source} \
         ! videorate \
         ! capsfilter name=fps_filter caps=video/x-raw,framerate={fps_num}/{fps_den} \
         ! videoscale \
         ! video/x-raw,width={target_w},height={target_h},pixel-aspect-ratio=1/1 \
         ! videoconvert \
         ! video/x-raw,format=RGB \
         ! jpegenc quality={jpeg_quality} \
         ! appsink name=sink emit-signals=false sync=false max-buffers=2 drop=true"
    );

    let pipeline = gst::parse::launch(&pipeline_str)
        .map_err(|e| CaptureError::PipelineFailed(format!("parse-launch error: {e}")))?
        .dynamic_cast::<gst::Pipeline>()
        .map_err(|_| {
            CaptureError::PipelineFailed("launch did not return a pipeline".to_string())
        })?;

    Ok(pipeline)
}

fn fps_to_fraction(fps: f32) -> (i32, i32) {
    let milli = (fps * 1000.0).round().clamp(200.0, 5000.0) as i32;
    (milli, 1000)
}
