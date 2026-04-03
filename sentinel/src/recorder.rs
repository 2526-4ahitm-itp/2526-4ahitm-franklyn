use std::env;
#[cfg(target_os = "linux")]
use std::os::fd::AsRawFd;
use std::sync::{
    Arc,
    atomic::{AtomicBool, AtomicU32, Ordering},
};
use std::time::{Duration, Instant};

#[cfg(target_os = "linux")]
use ashpd::{
    desktop::{
        CreateSessionOptions, PersistMode, Session,
        screencast::{CursorMode, Screencast, SelectSourcesOptions, SourceType},
    },
    enumflags2::BitFlags,
};
use gstreamer as gst;
use gstreamer::prelude::*;
use gstreamer_app as gst_app;
use tokio::sync::mpsc::error::TrySendError;
use tokio::sync::mpsc::{Receiver, Sender, channel};
use tracing::{error, info, warn};

#[derive(Debug, Clone)]
pub struct JpegBlob {
    pub data: Vec<u8>,
    pub _sequence: u64,
}

#[derive(Debug, Clone)]
pub enum CaptureOutput {
    Jpeg(JpegBlob),
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
    _Quartz,
    Windows,
}

#[derive(Debug, Clone, Copy)]
enum PipelineProfile {
    Primary,
    Fallback,
}

#[cfg(target_os = "linux")]
#[derive(Debug)]
struct PortalCapture {
    fd: std::os::fd::OwnedFd,
    node_id: u32,
    _proxy: Screencast,
    _session: Session<Screencast>,
}

#[cfg(not(target_os = "linux"))]
#[derive(Debug)]
struct PortalCapture {}

#[derive(Debug)]
pub struct Recorder {
    pipeline: gst::Pipeline,
    stop_flag: Arc<AtomicBool>,
    _fps_milli: Arc<AtomicU32>,
    _backend: Backend,
    _fps_filter: gst::Element,
    _portal_capture: Option<PortalCapture>,
}

impl Recorder {
    pub async fn start() -> Result<(Self, Receiver<CaptureOutput>), CaptureError> {
        gst::init().map_err(|e| CaptureError::GstreamerInit(e.to_string()))?;

        // TODO: remove the weird stuff like use_portal etc.
        let backend = detect_backend()?;
        let fps = 2.0;
        let quality = 70;
        let max_dimension = 1920;

        let use_portal = matches!(backend, Backend::Wayland);

        info!(
            backend = ?backend,
            use_portal,
            fps,
            jpeg_quality = quality,
            max_dimension,
            "starting screen recorder"
        );

        #[cfg(target_os = "linux")]
        let portal_capture = if use_portal {
            Some(start_portal_capture().await?)
        } else {
            None
        };
        #[cfg(not(target_os = "linux"))]
        let portal_capture: Option<PortalCapture> = None;

        let (pipeline, appsink, fps_filter) = match start_pipeline_with_profile(
            backend,
            fps,
            quality,
            portal_capture.as_ref(),
            PipelineProfile::Primary,
        ) {
            Ok(pipeline_parts) => pipeline_parts,
            Err(primary_err) if matches!(backend, Backend::Wayland) => {
                warn!(
                    error = %primary_err,
                    "primary pipeline failed to start, retrying with fallback profile"
                );
                start_pipeline_with_profile(
                    backend,
                    fps,
                    quality,
                    portal_capture.as_ref(),
                    PipelineProfile::Fallback,
                )?
            }
            Err(err) => return Err(err),
        };

        info!("recorder pipeline started");

        let (tx, rx) = channel::<CaptureOutput>(100);
        let stop_flag = Arc::new(AtomicBool::new(false));
        let stop_flag_task = Arc::clone(&stop_flag);
        let stop_flag_bus = Arc::clone(&stop_flag);

        tokio::task::spawn_blocking(move || pull_jpegs(appsink, tx, stop_flag_task));

        let bus = pipeline.bus().expect("gst::Pipeline always has a bus!");
        tokio::task::spawn_blocking(move || monitor_bus(bus, stop_flag_bus));

        Ok((
            Self {
                pipeline,
                stop_flag,
                _fps_milli: Arc::new(AtomicU32::new((fps * 1000.0) as u32)),
                _backend: backend,
                _fps_filter: fps_filter,
                _portal_capture: portal_capture,
            },
            rx,
        ))
    }

    pub fn set_quality(&self, _q: u32) {
        warn!("NOT IMPLEMENTED")
        // assert!(q <= 100);
        //
        // let jpegenc = self.pipeline
        // .by_name("jpegenc")
        // .expect("jpegenc not found");
        //
        // jpegenc.set_property("quality", q);
    }

    pub fn stop(&self) {
        self.stop_flag.store(true, Ordering::Relaxed);
        if let Err(err) = self.pipeline.set_state(gst::State::Null) {
            error!(error = ?err, "failed to stop recorder pipeline");
        } else {
            info!("recorder pipeline stopped");
        }
    }
}

impl Drop for Recorder {
    fn drop(&mut self) {
        self.stop();
    }
}

// Producer for ws
fn pull_jpegs(appsink: gst_app::AppSink, tx: Sender<CaptureOutput>, stop_flag: Arc<AtomicBool>) {
    let mut sequence = 0u64;
    let mut last_frame_at = Instant::now();
    let mut last_stall_log_at = Instant::now() - Duration::from_secs(3);

    loop {
        if stop_flag.load(Ordering::Relaxed) {
            info!(sequence, "stopping jpeg pull loop");
            break;
        }

        let Some(sample) = appsink.try_pull_sample(gst::ClockTime::from_mseconds(500)) else {
            let now = Instant::now();
            // debugging purposes
            if now.duration_since(last_frame_at) >= Duration::from_secs(3)
                && now.duration_since(last_stall_log_at) >= Duration::from_secs(3)
            {
                warn!(
                    stalled_ms = now.duration_since(last_frame_at).as_millis(),
                    "no sample pulled from appsink"
                );
                last_stall_log_at = now;
            }
            continue;
        };

        let Some(buffer) = sample.buffer() else {
            warn!("pulled sample without buffer");
            continue;
        };

        let Ok(map) = buffer.map_readable() else {
            warn!("failed to map jpeg buffer as readable");
            continue;
        };

        last_frame_at = Instant::now();

        let blob = JpegBlob {
            data: map.as_slice().to_vec(),
            _sequence: sequence,
        };

        match tx.try_send(CaptureOutput::Jpeg(blob)) {
            Ok(()) => {
                sequence += 1;
            }
            Err(TrySendError::Full(_)) => {
                warn!("dropping jpeg frame because channel is full");
            }
            Err(TrySendError::Closed(_)) => {
                error!("capture output channel closed");
                break;
            }
        }
    }
}

fn monitor_bus(bus: gst::Bus, stop_flag: Arc<AtomicBool>) {
    loop {
        if stop_flag.load(Ordering::Relaxed) {
            break;
        }

        let Some(msg) = bus.timed_pop(gst::ClockTime::from_mseconds(500)) else {
            continue;
        };

        let src = msg
            .src()
            .map(|s| s.path_string().to_string())
            .unwrap_or_else(|| "unknown".to_string());

        match msg.view() {
            gst::MessageView::Error(err) => {
                error!(
                    source = %src,
                    error = %err.error(),
                    debug = ?err.debug(),
                    "gstreamer pipeline error"
                );
                stop_flag.store(true, Ordering::Relaxed);
                break;
            }
            gst::MessageView::Warning(warn_msg) => {
                warn!(
                    source = %src,
                    warning = %warn_msg.error(),
                    debug = ?warn_msg.debug(),
                    "gstreamer pipeline warning"
                );
            }
            gst::MessageView::Eos(..) => {
                warn!(source = %src, "gstreamer pipeline reached end-of-stream");
                stop_flag.store(true, Ordering::Relaxed);
                break;
            }
            _ => {}
        }
    }
}

fn start_pipeline_with_profile(
    backend: Backend,
    fps: f32,
    jpeg_quality: u8,
    portal_capture: Option<&PortalCapture>,
    profile: PipelineProfile,
) -> Result<(gst::Pipeline, gst_app::AppSink, gst::Element), CaptureError> {
    let pipeline = build_pipeline(backend, fps, jpeg_quality, portal_capture, profile)?;

    let appsink = pipeline
        .by_name("sink")
        .ok_or_else(|| CaptureError::PipelineFailed("appsink not found".to_string()))?
        .dynamic_cast::<gst_app::AppSink>()
        .map_err(|_| CaptureError::PipelineFailed("sink is not an appsink".to_string()))?;

    let fps_filter = pipeline
        .by_name("fps_filter")
        .ok_or_else(|| CaptureError::PipelineFailed("fps filter not found".to_string()))?;

    pipeline
        .set_state(gst::State::Playing)
        .map_err(|e| CaptureError::PipelineFailed(format!("failed to set playing state: {e:?}")))?;

    if let Err(reason) = warm_up_pipeline(&pipeline, &appsink) {
        let _ = pipeline.set_state(gst::State::Null);
        return Err(CaptureError::PipelineFailed(format!(
            "pipeline warm-up failed with {:?} profile: {reason}",
            profile
        )));
    }

    Ok((pipeline, appsink, fps_filter))
}

fn warm_up_pipeline(pipeline: &gst::Pipeline, appsink: &gst_app::AppSink) -> Result<(), String> {
    // TODO: Do not throw sample away and return it
    if appsink
        .try_pull_sample(gst::ClockTime::from_seconds(2))
        .is_some()
    {
        return Ok(());
    }

    // if it failed, log why it failed.
    if let Some(bus) = pipeline.bus() {
        for _ in 0..20 {
            let Some(msg) = bus.timed_pop(gst::ClockTime::from_mseconds(10)) else {
                break;
            };

            match msg.view() {
                gst::MessageView::Error(err) => {
                    return Err(format!(
                        "{} ({:?})",
                        err.error(),
                        err.debug().unwrap_or_default()
                    ));
                }
                gst::MessageView::Eos(..) => {
                    return Err("received EOS during startup".to_string());
                }
                _ => {}
            }
        }
    }

    Err("no sample received during pipeline startup".to_string())
}

fn detect_backend() -> Result<Backend, CaptureError> {
    if cfg!(target_os = "windows") {
        return Ok(Backend::Windows);
    }

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

#[cfg(target_os = "linux")]
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
                // TODO: if cursor is not supported, do not fail or just don't get the cursor
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

    // there will never be multiple sources selecte
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
        _proxy: proxy,
        _session: session,
    })
}

fn build_pipeline(
    backend: Backend,
    fps: f32,
    jpeg_quality: u8,
    portal_capture: Option<&PortalCapture>,
    profile: PipelineProfile,
) -> Result<gst::Pipeline, CaptureError> {
    let (fps_num, fps_den) = fps_to_fraction(fps);

    let source = match backend {
        #[cfg(target_os = "linux")]
        Backend::Wayland => {
            let capture = portal_capture.ok_or_else(|| {
                CaptureError::PipelineFailed(
                    "picker mode selected without portal capture".to_string(),
                )
            })?;

            format!(
                "pipewiresrc fd={} path={} do-timestamp=true always-copy=true",
                capture.fd.as_raw_fd(),
                capture.node_id
            )
        }
        #[cfg(not(target_os = "linux"))]
        Backend::Wayland => panic!("Wayland is not supported on this platform"),

        #[cfg(target_os = "linux")]
        Backend::X11 => "ximagesrc use-damage=false".to_string(),
        #[cfg(not(target_os = "linux"))]
        Backend::X11 => panic!("X11 is not supported on this platform"),

        Backend::Windows => "d3d11screencapturesrc".to_string(),
        backend => panic!("UNSUPPORTED BACKEND: {:?}", backend),
    };

    info!(source);

    let pipeline_str = match profile {
        PipelineProfile::Primary => format!(
            "{source} \
             ! queue max-size-buffers=4 leaky=downstream \
             ! videoconvert \
             ! videoscale \
             ! videorate \
             ! capsfilter name=fps_filter caps=video/x-raw,framerate={fps_num}/{fps_den} \
             ! capsfilter name=res_filter caps=video/x-raw,width=1920,height=1080,pixel-aspect-ratio=1/1 \
             ! jpegenc quality={jpeg_quality} \
             ! appsink name=sink emit-signals=false sync=false max-buffers=2 drop=true"
        ),
        PipelineProfile::Fallback => format!(
            "{source} \
             ! queue max-size-buffers=4 leaky=downstream \
             ! videoconvert \
             ! videorate \
             ! capsfilter name=fps_filter caps=video/x-raw,framerate={fps_num}/{fps_den} \
             ! jpegenc quality={jpeg_quality} \
             ! appsink name=sink emit-signals=false sync=false max-buffers=2 drop=true"
        ),
    };

    info!("Using pipeline: {}", pipeline_str);

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
