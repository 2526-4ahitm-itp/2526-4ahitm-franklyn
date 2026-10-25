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

pub mod source;

use anyhow::{Ok, Result};
use futures_util::StreamExt;
use gstreamer_app::AppSink;
use gstreamer_video::VideoConverter;
use std::{
    os::{fd::AsRawFd, unix::io::RawFd},
    time::Duration,
};
use tokio::{
    sync::mpsc::{self, Receiver},
    time::{sleep, timeout},
};
use tokio_util::{sync::CancellationToken, task::TaskTracker};
use tracing::{debug, error, info, instrument, warn};

use gstreamer::{
    ClockTime, Element, ElementFactory, Message, Pipeline, State, StateChangeSuccess,
    glib::object::Cast,
    prelude::{ElementExt, GstBinExtManual},
};

use crate::recorder_v3::source::Source;

pub trait DataUnit: From<gstreamer::Sample> + Send {}

#[derive(Debug, Clone)]
pub struct JPegBase64 {
    pub data: String,
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

/// Source not yet acquired; holds configuration only.
pub struct Initialized {
    source: Source,
}

/// Source acquired, pipeline built and ready to control.
#[derive(Debug)]
pub struct Ready {
    pipeline: Pipeline,

    cancellation_token: CancellationToken,
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

        let src = match &self.inner.source {
            Source::PipeWire {
                fd,
                node_id,
                session: _,
                restore_token: _,
            } => ElementFactory::make("pipewiresrc")
                .property("fd", fd.as_raw_fd())
                .property("path", format!("{}", node_id))
                .property("min-buffers", 1i32)
                .property("do-timestamp", true)
                .property("always-copy", true)
                .build(),
            Source::AvfScreen { display_id: _ } => ElementFactory::make("avfvideosrc")
                .property("capture-screen", true)
                .property("capture-screen-cursor", true)
                .property("do-timestamp", true)
                .build(),
            Source::D3d11Screen { monitor } => ElementFactory::make("d3d11screencapturesrc")
                .property("monitor-index", i32::try_from(*monitor).unwrap_or(-1))
                .property("show-cursor", true)
                .property("do-timestamp", true)
                .build(),
            Source::XImage { display_name } => ElementFactory::make("ximagesrc")
                .property("use-damage", false)
                .property("show-pointer", true)
                .property("display-name", display_name)
                .property("do-timestamp", true)
                .build(),
        }?;

        let queue = ElementFactory::make("queue")
            .property("max-size-buffers", 4u32)
            .property_from_str("leaky", "downstream")
            .build()?;

        let videoconvert = ElementFactory::make("videoconvert").build()?;

        let videoscale = ElementFactory::make("videoscale").build()?;

        let videorate = ElementFactory::make("videorate").build()?;

        let fps_filter = ElementFactory::make("capsfilter")
            .property("name", "fps_filter")
            .property(
                "caps",
                gstreamer_video::VideoCapsBuilder::for_encoding("video/x-raw")
                    .framerate(gstreamer::Fraction::new(2, 1))
                    .build(),
            )
            .build()?;

        let res_filter = ElementFactory::make("capsfilter")
            .property("name", "res_filter")
            .property(
                "caps",
                gstreamer_video::VideoCapsBuilder::for_encoding("video/x-raw")
                    .width(1920)
                    .height(1080)
                    .build(),
            )
            .build()?;

        let jpeg_encode = ElementFactory::make("jpegenc")
            .property("quality", 70)
            .build()?;

        let appsink = AppSink::builder()
            .name("sink")
            .sync(false)
            .property("emit-signals", false)
            .max_buffers(2)
            .drop(true)
            .build();

        let pipeline = Pipeline::with_name("main-pipeline");

        let elements: [&Element; 9] = [
            &src,
            &videoconvert,
            &videoscale,
            &videorate,
            &queue,
            &fps_filter,
            &res_filter,
            &jpeg_encode,
            appsink.upcast_ref(),
        ];

        pipeline.add_many(elements)?;
        gstreamer::Element::link_many(elements)?;

        pipeline.set_state(State::Ready)?;

        let cancellation_token = CancellationToken::new();
        let tracker = TaskTracker::new();

        let (tx, rx) = mpsc::channel::<DU>(100);

        dbg!(&pipeline);
        dbg!(&pipeline.bus());

        tracker.spawn(watch_bus(
            pipeline.bus().expect("Bus always exists"),
            cancellation_token.clone(),
        ));

        tracker.spawn(get_thumbnails(
            appsink,
            tx.clone(),
            cancellation_token.clone(),
        ));

        Ok((
            Recorder {
                inner: Ready {
                    pipeline,
                    cancellation_token,
                    tracker,
                },
            },
            rx,
        ))
    }
}

impl Recorder<Ready> {
    /// Returns once pipeline actually reached `state`.
    async fn transition(&self, state: State) -> Result<()> {
        match self.inner.pipeline.set_state(state)? {
            StateChangeSuccess::Success | StateChangeSuccess::NoPreroll => Ok(()),
            StateChangeSuccess::Async => {
                let pipeline = self.inner.pipeline.clone();
                tokio::task::spawn_blocking(move || pipeline.state(ClockTime::from_seconds(5)).0)
                    .await??;
                Ok(())
            }
        }
    }

    pub async fn play(&self) -> Result<()> {
        self.transition(State::Playing).await
    }

    pub async fn pause(&self) -> Result<()> {
        self.transition(State::Paused).await
    }

    /// Tears down the pipeline and ends the frame stream.
    pub async fn stop(self) -> Result<()> {
        self.transition(State::Null).await?;
        self.inner.cancellation_token.cancel();
        timeout(Duration::from_secs(5), self.inner.tracker.wait()).await?;
        Ok(())
    }
}

#[instrument(skip_all)]
async fn get_thumbnails<DU: DataUnit>(
    appsink: AppSink,
    tx: mpsc::Sender<DU>,
    stop: CancellationToken,
) -> Result<()> {
    info!("Start getting video");
    let mut stream = appsink.stream();

    loop {
        tokio::select! {
            Some(sample) = stream.next() => {
                let du: DU = DU::from(sample);
                tx.try_send(du).ok();
            },
            _ = stop.cancelled() => {
                info!("Cancellation token stopped. stopping get thumbnails...");
                return Ok(());
            }
        }
    }
}

#[instrument(skip_all)]
async fn watch_bus(bus: gstreamer::Bus, stop: CancellationToken) -> Result<()> {
    let mut messages = bus.stream();

    loop {
        tokio::select! {
            Some(msg) = messages.next() => {
                handle_bus_message(msg)?;
            },
            _ = stop.cancelled() => {
                info!("Cancellation token stopped. stopping watching bus...");
                break;
            }
        };
    }

    Ok(())
}

fn handle_bus_message(msg: Message) -> Result<()> {
    use gstreamer::MessageView;

    match msg.view() {
        MessageView::Eos(..) => {
            warn!("recorder: End of stream");
            Ok(())
        }
        MessageView::Error(err) => {
            error!("recorder: Bus watcher failed.");
            dbg!(err);
            Err(anyhow::anyhow!(
                "error from {:?}: {} ({:?})",
                err.src().map(|s| s.to_string()),
                err.error(),
                err.debug()
            ))
        }
        MessageView::StateChanged(state) => {
            warn!("state changed:");
            dbg!(state);
            Ok(())
        }
        MessageView::Warning(warning) => {
            warn!("A warning");
            dbg!(warning);
            Ok(())
        }
        _ => {
            info!("Another random messages");
            Ok(())
        }
    }
}
