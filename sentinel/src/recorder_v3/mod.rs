//! Video capture pipeline with staged initialization.
//!
//! # Lifecycle
//!
//! ```rust
//! let recorder = Recorder::init(Source::V4l2 { device: "/dev/video0".into() });
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
//! Source::V4l2 { device: "/dev/video0".into() }
//! Source::PipeWire { fd }
//! Source::Test  // videotestsrc, no hardware required
//! ```
//!
//! # Error Handling
//!
//! All async methods return `anyhow::Result<_>`. Pipeline bus errors propagate
//! to the next awaited call and are forwarded on an [`ErrorReceiver`] channel.

use anyhow::Result;
use std::{marker::PhantomData, os::unix::io::RawFd, path::PathBuf, sync::mpsc};

use gstreamer::{Pipeline, State};

type Receiver<DU> = mpsc::Receiver<DU>;

#[derive(Debug, Clone)]
struct JPegBase64 {
    data: String,
}

#[derive(Debug, Clone)]
struct Test {
    data: i32,
}

pub enum SourceType {
    PipeWire,
    ScreenCaptureKit,
    GraphicsCapture,
}

/// Video source kind.
pub enum Source {
    PipeWire { fd: RawFd, node_id: u32 },
    ScreenCaptureKit { display_id: u32 },
    GraphicsCapture { monitor: isize },
}

/// Source not yet acquired; holds configuration only.
pub struct Initialized {
    source: SourceType,
}

/// Source acquired, pipeline built and ready to control.
#[derive(Debug)]
pub struct Ready<DU> {
    pipeline: Pipeline,
    state: State,
    rx: Receiver<DU>,
}

#[derive(Debug)]
pub struct Recorder<S> {
    inner: S,
}

impl Recorder<Initialized> {
    pub fn init(source: SourceType) -> Self {
        Self {
            inner: Initialized { source },
        }
    }

    /// Acquire the source and build the GStreamer pipeline.
    pub async fn acquire<DU>(self) -> Result<(Recorder<Ready<DU>>, Receiver<DU>)> {
        match self.inner.source {
            SourceType::PipeWire => todo!(),
            SourceType::ScreenCaptureKit => todo!(),
            SourceType::GraphicsCapture => todo!(),
        }
    }
}

impl<DU> Recorder<Ready<DU>> {
    pub async fn play(&self) -> Result<()> {
        todo!()
    }
    pub async fn pause(&self) -> Result<()> {
        todo!()
    }
    /// Tears down the pipeline and ends the frame stream.
    pub async fn stop(self) -> Result<()> {
        todo!()
    }
}
