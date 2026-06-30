
//! Video capture pipeline with staged initialization.
//!
//! # Lifecycle
//!
//! ```rust
//! let recorder = Recorder::fresh(Source::V4l2 { device: "/dev/video0".into() });
//! let (recorder, frames) = recorder.acquire().await?;
//! recorder.play().await?;
//! ```
//!
//! [`Recorder<Fresh>`] holds configuration only. [`Recorder::acquire`] opens the
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
//! All async methods return `Result<_, RecorderError>`. Pipeline bus errors propagate
//! to the next awaited call and are forwarded on an [`ErrorReceiver`] channel.

use std::{os::unix::io::RawFd, path::PathBuf};

use gstreamer::{Pipeline, State};

/// Video source kind.
pub enum Source {
    V4l2 { device: PathBuf },
    PipeWire { fd: RawFd },
    Test,
}

/// Source not yet acquired; holds configuration only.
pub struct Fresh {
    source: Source,
}

/// Source acquired, pipeline built and ready to control.
pub struct Ready {
    pipeline: Pipeline,
    state: State,
}

pub struct Recorder<S> {
    inner: S,
}

impl Recorder<Fresh> {
    pub fn fresh(source: Source) -> Self {
        Self { inner: Fresh { source } }
    }

    /// Acquire the source and build the GStreamer pipeline.
    pub async fn acquire(self) -> Result<(Recorder<Ready>, FrameReceiver), RecorderError> {
        todo!()
    }
}

impl Recorder<Ready> {
    pub async fn play(&self) -> Result<(), RecorderError> { todo!() }
    pub async fn pause(&self) -> Result<(), RecorderError> { todo!() }
    /// Tears down the pipeline and ends the frame stream.
    pub async fn stop(self) -> Result<(), RecorderError> { todo!() }
}

use gstreamer::{Pipeline, State};

pub struct Recorder {
    state: State,
    pipeline: Pipeline,
}
