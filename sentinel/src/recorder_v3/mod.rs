//! Video capture pipeline with staged initialization.
//!
//! # Lifecycle
//!
//! ```rust
//! let recorder = Recorder::init(SourceType::PipeWire { fd: "/dev/video0".into() });
//! let (recorder, frame_rx) = recorder.acquire().await?;
//! recorder.play().await?;
//! ```
//!
//! [`Recorder<Initialized>`] holds configuration only. [`Recorder::acquire`] opens the
//! source, builds the GStreamer pipeline, and returns a [`Recorder<Ready>`].
//!
//! # Sources
//!
//! ```rust
//! Source::PipeWire
//! ```
//!
//! # Error Handling
//!
//! All async methods return `anyhow::Result<_>`. Pipeline bus errors propagate
//! to the next awaited call and are forwarded on an [`ErrorReceiver`] channel.

use anyhow::Result;
use futures_util::StreamExt;
use gstreamer_app::AppSink;
use std::{
    os::{fd::AsRawFd, unix::io::RawFd},
    time::Duration,
};
use tokio::{
    sync::mpsc::{self, Receiver},
    time::timeout,
};
use tokio_util::{sync::CancellationToken, task::TaskTracker};
use tracing::{debug, error, info, instrument, warn};

use gstreamer::{
    ClockTime, ElementFactory, Message, Pipeline, State,
    glib::object::Cast,
    prelude::{ElementExt, GstBinExtManual},
};

trait DataUnit: From<gstreamer::Sample> + Send {}

#[derive(Debug, Clone)]
pub struct JPegBase64 {
    data: String,
}

impl DataUnit for JPegBase64 {}

impl From<gstreamer::Sample> for JPegBase64 {
    fn from(value: gstreamer::Sample) -> Self {
        use base64::{Engine as _, engine::general_purpose::STANDARD};

        let data = value
            .buffer()
            .and_then(|buf| buf.map_readable().ok())
            .map(|map| STANDARD.encode(map.as_slice()))
            .unwrap_or_default();

        Self { data }
    }
}

/// Video source kind.
pub enum Source {
    PipeWire { fd: RawFd, node_id: u32 },
    ScreenCaptureKit { display_id: u32 },
    GraphicsCapture { monitor: isize },
}

/// Source not yet acquired; holds configuration only.
pub struct Initialized {
    source: Source,
}

enum HealthcheckMessage {
    Ok,
    Error,
}

/// Source acquired, pipeline built and ready to control.
#[derive(Debug)]
pub struct Ready {
    pipeline: Pipeline,

    stop: CancellationToken,
    tracker: TaskTracker,
}

#[derive(Debug)]
pub struct Recorder<S> {
    inner: S,
}

impl Recorder<Initialized> {
    pub fn init(source: Source) -> Self {
        Self {
            inner: Initialized { source },
        }
    }

    /// Acquire the source and build the GStreamer pipeline.
    #[tracing::instrument(skip_all)]
    pub fn acquire<DU: DataUnit + 'static>(self) -> Result<(Recorder<Ready>, Receiver<DU>)> {
        gstreamer::init().expect("Gstreamer failed to initialize. Stopping...");

        let src = match self.inner.source {
            Source::PipeWire { fd, node_id } => ElementFactory::make("pipewiresrc")
                .property("fd", fd.as_raw_fd())
                .property("path", format!("{}", node_id))
                .property("do-timestamp", true)
                .property("always-copy", true)
                .build(),
            Source::ScreenCaptureKit { display_id } => todo!(),
            Source::GraphicsCapture { monitor } => todo!(),
        }?;

        let queue = ElementFactory::make("queue")
            .property("max-size-buffers", 4u32)
            .property_from_str("leaky", "downstream")
            .build()?;

        let fps_filter = ElementFactory::make("capsfilter")
            .property("name", "fps_filter")
            .property(
                "caps",
                gstreamer_video::VideoCapsBuilder::for_encoding("video/x-raw")
                    .framerate(gstreamer::Fraction::new(2, 1))
                    .build(),
            )
            .build()?;

        let res_fitler = ElementFactory::make("capsfilter")
            .property("name", "res_filter")
            .property(
                "caps",
                gstreamer_video::VideoCapsBuilder::for_encoding("video/x-raw")
                    .width(1920)
                    .height(1080)
                    .pixel_aspect_ratio(gstreamer::Fraction::new(1, 1))
                    .build(),
            )
            .build()?;

        let jpeg_encode = ElementFactory::make("jpegenc")
            .property("quality", 70)
            .build()?;

        let appsink = AppSink::builder()
            .name("sink")
            .sync(true)
            .max_buffers(2)
            .drop(true)
            .build();

        let pipeline = Pipeline::with_name("main-pipeline");

        pipeline.add_many(vec![
            &src,
            &queue,
            &res_fitler,
            &fps_filter,
            &jpeg_encode,
            appsink.upcast_ref(),
        ])?;

        pipeline.set_state(State::Ready)?;

        let stop = CancellationToken::new();
        let tracker = TaskTracker::new();

        let (tx, rx) = mpsc::channel::<DU>(100);

        dbg!(&pipeline);
        dbg!(&pipeline.bus());

        tracker.spawn(watch_bus(
            pipeline.bus().expect("Bus always exists"),
            stop.clone(),
        ));

        tracker.spawn(get_video(appsink, tx.clone()));

        Ok((
            Recorder {
                inner: Ready {
                    pipeline: pipeline,
                    stop,
                    tracker,
                },
            },
            rx,
        ))
    }
}

impl Recorder<Ready> {
    pub fn play(&self) -> Result<()> {
        self.inner.pipeline.set_state(State::Ready)?;

        Ok(())
    }

    pub fn pause(&self) -> Result<()> {
        self.inner.pipeline.set_state(State::Paused)?;

        Ok(())
    }

    /// Tears down the pipeline and ends the frame stream.
    pub async fn stop(self) -> Result<()> {
        self.inner.stop.cancel();
        timeout(Duration::from_secs(5), self.inner.tracker.wait()).await?;
        Ok(())
    }
}

#[instrument(skip_all)]
async fn get_video<DU: DataUnit>(appsink: AppSink, tx: mpsc::Sender<DU>) -> Result<()> {
    info!("Start getting video");
    while let Ok(sample) = appsink.pull_sample() {
        info!("pulled sample");
        let du: DU = DU::from(sample);

        tx.try_send(du).ok();
    }
    error!("End pulling samples");

    Ok(())
}

#[instrument(skip_all)]
async fn watch_bus(bus: gstreamer::Bus, stop: CancellationToken) -> Result<()> {
    let mut messages = bus.stream();

    loop {
        tokio::select! {
            Some(msg) = messages.next() => {
                handle(msg)?;
            },
            _ = stop.cancelled() => {
                break;
            }
        };
    }

    todo!()
}

fn handle(msg: Message) -> Result<()> {
    use gstreamer::MessageView;

    match msg.view() {
        MessageView::Eos(..) => {
            warn!("recorder: End of stream");
            Ok(())
        }
        MessageView::Error(err) => {
            error!("recorder: Bus watcher failed.");
            Err(anyhow::anyhow!(
                "error from {:?}: {} ({:?})",
                err.src().map(|s| s.to_string()),
                err.error(),
                err.debug()
            ))
        }
        MessageView::StateChanged(..) => Ok(()),
        _ => Ok(()),
    }
}
