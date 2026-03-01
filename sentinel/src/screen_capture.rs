use std::sync::OnceLock;
#[cfg(not(target_os = "macos"))]
use std::{process::exit, sync::mpsc};

use base64::Engine;
use tokio::sync::{
    RwLock,
    mpsc::{Receiver, Sender},
};
#[cfg(not(target_os = "macos"))]
use tracing::error;
use tracing::{debug, info, warn};
use xcap::{
    Frame,
    image::{ExtendedColorType, ImageEncoder, codecs::png::PngEncoder},
};
#[cfg(not(target_os = "macos"))]
use xcap::{Monitor, VideoRecorder};

#[cfg(any(env = "dev", target_os = "macos"))]
static GENERATE_FRAME_WIDTH: usize = 192;

#[derive(Debug, Clone)]
pub(crate) enum RecordControlMessage {
    GetFrame,
    StartRecording,
    StopRecording,
}

#[derive(Debug, Clone)]
pub(crate) enum FrameResponse {
    Frame(String),
    NoFrame,
}

static GLOBAL_FRAME: OnceLock<RwLock<xcap::Frame>> = OnceLock::new();

#[tracing::instrument(skip(frame_tx, ctrl_rx))]
pub(crate) async fn start_screen_recording(
    mut ctrl_rx: Receiver<RecordControlMessage>,
    frame_tx: Sender<FrameResponse>,
) {
    #[cfg(not(target_os = "macos"))]
    let mut video_recorder: Option<VideoRecorder> = None;

    #[cfg(not(target_os = "macos"))]
    {
        let monitor = Monitor::from_point(100, 100).unwrap();
        let sx: mpsc::Receiver<Frame>;
        let mut failed_screen_grab_attempts = 0;

        loop {
            let res = monitor.video_recorder();

            if let Ok((vr, s)) = res {
                debug!("got video recorder");
                video_recorder = Some(vr);
                sx = s;
                tokio::spawn(async move {
                    loop {
                        match sx.recv() {
                            Ok(frame) => {
                                // if not initialized
                                if let Some(lock_rwl) = GLOBAL_FRAME.get() {
                                    let mut lock = lock_rwl.write().await;
                                    *lock = frame;
                                } else {
                                    GLOBAL_FRAME.set(RwLock::new(frame)).unwrap();
                                }
                            }
                            _ => continue,
                        }
                    }
                });
                break;
            }

            failed_screen_grab_attempts += 1;
            if failed_screen_grab_attempts >= 2 {
                if cfg!(env = "prod") {
                    error!("video recorder in None! exiting...");
                    exit(1);
                } else {
                    warn!("failed to get video recorder! Using fake frames.");
                }
                break;
            }
        }
    }

    #[cfg(target_os = "macos")]
    warn!("macOS detected: skipping video recorder, using fake frames.");

    loop {
        if let Some(ctrl_message) = ctrl_rx.recv().await {
            match ctrl_message {
                RecordControlMessage::GetFrame => {
                    let frame: Option<Frame>;
                    info!("GetFrame called");

                    if let Some(frame_rwl) = GLOBAL_FRAME.get() {
                        frame = Some(frame_rwl.read().await.clone());
                    } else {
                        #[cfg(any(env = "dev", target_os = "macos"))]
                        {
                            use crate::image_generator::generate_random_image;
                            let data = generate_random_image(GENERATE_FRAME_WIDTH);
                            frame = Some(Frame::new(data.0 as u32, data.1 as u32, data.2))
                        }
                        #[cfg(all(env = "prod", not(target_os = "macos")))]
                        {
                            frame = None;
                        }
                    }

                    if let Some(frame) = frame {
                        // do processing before sending
                        let (w, h) = (frame.width, frame.height);
                        let mut out = Vec::new();
                        let _ = PngEncoder::new(&mut out)
                            .write_image(&frame.raw, w, h, ExtendedColorType::Rgba8)
                            .unwrap();
                        let base64 = base64::engine::general_purpose::STANDARD.encode(out);
                        let _ = frame_tx.send(FrameResponse::Frame(base64)).await;
                    } else {
                        info!("sending real frame");
                        frame_tx.send(FrameResponse::NoFrame).await.unwrap();
                    }
                }
                RecordControlMessage::StopRecording => {
                    debug!("stop recording");
                    #[cfg(not(target_os = "macos"))]
                    if let Some(vr) = video_recorder.as_ref() {
                        let _ = vr.stop();
                    }
                }
                RecordControlMessage::StartRecording => {
                    debug!("start recording");
                    #[cfg(not(target_os = "macos"))]
                    if let Some(vr) = video_recorder.as_ref() {
                        let _ = vr.start();
                    }
                }
            };
        }
    }
}
