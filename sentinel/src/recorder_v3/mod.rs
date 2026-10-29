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

use anyhow::{Ok, Result, anyhow};
use chrono::{TimeDelta, Utc};
use futures_util::StreamExt;
use gstreamer_app::AppSink;
use std::{env, os::fd::AsRawFd, time::Duration};
use thiserror::Error;
use tokio::{
    sync::{mpsc, watch},
    time::{sleep, timeout},
};
use tokio_util::{sync::CancellationToken, task::TaskTracker};
use tracing::{debug, error, info, instrument, warn};

use gstreamer::{
    ClockTime, Element, ElementFactory, Message, Pipeline, State, StateChangeSuccess,
    glib::object::Cast,
    prelude::{ElementExt, ElementExtManual, GstBinExtManual},
};

use crate::recorder_v3::source::Source;

pub trait DataUnit: From<gstreamer::Sample> + Send + Sync {}

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

#[derive(Debug, Clone, Error)]
pub enum RecorderError {
    #[error("End of Stream")]
    BusEndOfStream,

    #[error("Bus error: {0}")]
    BusError(String),

    #[error("No frames received for longer than {0} seconds")]
    NoFrames(i64),
}

#[derive(Debug)]
pub struct Recorder {
    pipeline: Pipeline,

    source: Source,

    cancellation_token: CancellationToken,
    tracker: TaskTracker,
}

impl Drop for Recorder {
    fn drop(&mut self) {
        let _ = self.pipeline.set_state(State::Null);
        self.cancellation_token.cancel();
    }
}

impl Recorder {
    /// Acquire the source and build the GStreamer pipeline.
    #[tracing::instrument(skip_all)]
    pub fn build<DU: DataUnit + 'static>(
        source: Source,
    ) -> Result<(
        Self,
        watch::Receiver<Option<DU>>,
        mpsc::Receiver<RecorderError>,
    )> {
        init_gstreamer()?;

        let (pipeline, appsink) = match Self::make_pipeline(&source, false) {
            Result::Ok(res) => res,
            Err(err) => {
                warn!("Failed to create main pipeline: {}", err);
                match Self::make_pipeline(&source, true) {
                    Result::Ok(res) => res,
                    Err(err) => {
                        return Err(anyhow!(
                            "Failed to create backup pipeline too, now exitting completely: {}",
                            err
                        ));
                    }
                }
            }
        };

        let cancellation_token = CancellationToken::new();
        let tracker = TaskTracker::new();

        let (tx, rx) = watch::channel::<Option<DU>>(None);
        let (errors_tx, errors_rx) = mpsc::channel::<RecorderError>(10);

        tracker.spawn(watch_bus(
            pipeline.bus().expect("Bus always exists"),
            cancellation_token.clone(),
            errors_tx.clone(),
        ));

        tracker.spawn(get_thumbnails(
            appsink,
            tx,
            errors_tx,
            cancellation_token.clone(),
        ));

        Ok((
            Recorder {
                pipeline,
                cancellation_token,
                tracker,
                source,
            },
            rx,
            errors_rx,
        ))
    }

    fn make_pipeline(source: &Source, backup: bool) -> Result<(Pipeline, AppSink)> {
        let src = source.make_element()?;
        let queue = ElementFactory::make("queue")
            .property("max-size-buffers", 4u32)
            .property_from_str("leaky", "downstream")
            .build()?;

        let videoconvert = ElementFactory::make("videoconvert").build()?;

        let videorate = ElementFactory::make("videorate").build()?;

        let videoscale = ElementFactory::make("videoscale").build()?;

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

        let elements: Vec<&Element> = vec![
            Some(&src),
            Some(&queue),
            Some(&videoconvert),
            Some(&videorate),
            (!backup).then_some(&videoscale),
            Some(&fps_filter),
            (!backup).then_some(&res_filter),
            Some(&jpeg_encode),
            Some(appsink.upcast_ref()),
        ]
        .into_iter()
        .flatten()
        .collect();

        pipeline.add_many(&elements)?;
        gstreamer::Element::link_many(elements)?;

        let _ = pipeline.set_state(State::Playing);

        if let Err(err) = warm_up_pipeline(&pipeline, &appsink) {
            let _ = pipeline.set_state(State::Null);
            return Err(anyhow!("failed to create pipeline: {}", err));
        }

        Ok((pipeline, appsink))
    }

    /// Tears down the pipeline and ends the frame stream.
    pub async fn stop(self) -> Result<()> {
        match self.pipeline.set_state(State::Null)? {
            StateChangeSuccess::Success | StateChangeSuccess::NoPreroll => {}
            StateChangeSuccess::Async => {
                let pipeline = self.pipeline.clone();

                let mut tries = 0;

                tokio::task::spawn_blocking(move || {
                    while tries < 20 * 5 {
                        if pipeline.state(ClockTime::from_mseconds(50)).1 == State::Null {
                            break;
                        }
                        tries += 1;
                    }
                })
                .await
                .ok();
            }
        }

        self.cancellation_token.cancel();
        timeout(Duration::from_secs(5), self.tracker.wait()).await?;
        Ok(())
    }
}

#[instrument(skip_all)]
async fn get_thumbnails<DU: DataUnit>(
    appsink: AppSink,
    tx: watch::Sender<Option<DU>>,
    errors_tx: mpsc::Sender<RecorderError>,
    stop: CancellationToken,
) -> Result<()> {
    info!("Start getting video");

    let mut last_frame = chrono::Utc::now();

    let mut stream = appsink.stream();

    loop {
        tokio::select! {
            _ = sleep(Duration::from_secs(3)) => {
                let delta = Utc::now() - last_frame;
                warn!("haven't pulled sample for {}s", delta.num_seconds());
                if delta >= TimeDelta::seconds(10)
                    && errors_tx.try_send(RecorderError::NoFrames(delta.num_seconds())).is_err() {
                        debug!("recorder errors channel is full or closed")
                    }
            },
            Some(sample) = stream.next() => {
                let du: DU = DU::from(sample);
                last_frame = Utc::now();
                tx.send(Some(du)).ok();
            },
            _ = stop.cancelled() => {
                info!("Cancellation token stopped. stopping get thumbnails...");
                return Ok(());
            }
        }
    }
}

#[instrument(skip_all)]
async fn watch_bus(
    bus: gstreamer::Bus,
    stop: CancellationToken,
    errors_tx: mpsc::Sender<RecorderError>,
) -> Result<()> {
    info!("watching bus");
    let mut messages = bus.stream();

    loop {
        tokio::select! {
            Some(msg) = messages.next() => {
                if let Err(err) = handle_bus_message(msg)
                    && errors_tx.try_send(err).is_err() {
                        debug!("recorder errors channel is full or closed")
                    }
            },
            _ = stop.cancelled() => {
                info!("Cancellation token stopped. stopping watching bus...");
                break;
            },
        };
    }

    Ok(())
}

fn handle_bus_message(msg: Message) -> Result<(), RecorderError> {
    use gstreamer::MessageView;

    match msg.view() {
        MessageView::Eos(..) => {
            error!("recorder: End of stream");
            Err(RecorderError::BusEndOfStream)
        }
        MessageView::Error(err) => {
            error!("recorder: Bus watcher failed.");
            Err(RecorderError::BusError(format!(
                "error from {:?}: {} ({:?})",
                err.src().map(|s| s.to_string()),
                err.error(),
                err.debug()
            )))
        }
        MessageView::StateChanged(..) => Result::Ok(()),
        MessageView::Warning(..) => {
            warn!("A warning");
            Result::Ok(())
        }
        _ => Result::Ok(()),
    }
}

fn warm_up_pipeline(
    pipeline: &gstreamer::Pipeline,
    appsink: &gstreamer_app::AppSink,
) -> Result<()> {
    debug!("checking health of pipeline...");
    if appsink
        .try_pull_sample(gstreamer::ClockTime::from_seconds(2))
        .is_some()
    {
        return Result::Ok(());
    }

    // if it failed, log why it failed.
    if let Some(bus) = pipeline.bus() {
        for _ in 0..20 {
            let Some(msg) = bus.timed_pop(gstreamer::ClockTime::from_mseconds(10)) else {
                break;
            };

            match msg.view() {
                gstreamer::MessageView::Error(err) => {
                    return Err(anyhow!(
                        "{} ({:?})",
                        err.error(),
                        err.debug().unwrap_or_default()
                    ));
                }
                gstreamer::MessageView::Eos(..) => {
                    return Err(anyhow!("received EOS during startup"));
                }
                _ => {}
            }
        }
    }

    Err(anyhow!("no sample received during pipeline startup"))
}

fn init_gstreamer() -> Result<()> {
    let exe_path = env::current_exe();
    #[cfg(target_os = "macos")]
    let exe_path = exe_path.and_then(|p| p.canonicalize());

    if let Result::Ok(exe_path) = exe_path
        && let Some(root) = exe_path.parent().and_then(|p| p.parent())
    {
        let plugin_path = root.join("lib").join("gstreamer-1.0");
        let scanner = root.join("libexec").join("gst-plugin-scanner");

        unsafe {
            if plugin_path.is_dir() {
                env::set_var("GST_PLUGIN_PATH", &plugin_path);
            }
            if scanner.is_file() {
                env::set_var("GST_PLUGIN_SCANNER", &scanner);
            }
        };
    }

    gstreamer::init()?;
    Ok(())
}
