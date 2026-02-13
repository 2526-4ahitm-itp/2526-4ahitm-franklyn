use std::sync::{OnceLock, mpsc};

use base64::Engine;
use tokio::sync::{
    RwLock,
    mpsc::{Receiver, Sender},
};
use xcap::{
    Frame, Monitor, VideoRecorder,
    image::{ExtendedColorType, ImageEncoder, codecs::png::PngEncoder},
};

#[cfg(env = "dev")]
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

pub(crate) async fn start_screen_recording(
    mut ctrl_rx: Receiver<RecordControlMessage>,
    frame_tx: Sender<FrameResponse>,
) {
    let monitor = Monitor::from_point(100, 100).unwrap();

    dbg!("pre");

    let mut video_recorder: Option<VideoRecorder> = None;
    let sx: mpsc::Receiver<Frame>;

    let mut failed_screen_grab_attempts = 0;

    loop {
        let res = monitor.video_recorder();

        if let Ok((vr, s)) = res {
            video_recorder = Some(vr);
            sx = s;
            tokio::spawn(async move {
                loop {
                    match sx.recv() {
                        Ok(frame) => {
                            println!("frame: {:?}", frame.width);
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
        } else if let Err(e) = res {
            eprintln!("couldn't get video recorder");
            dbg!(e);
        }

        failed_screen_grab_attempts += 1;
        if failed_screen_grab_attempts >= 2 {
            break;
        }
    }

    dbg!("post");

    loop {
        if let Some(ctrl_message) = ctrl_rx.recv().await {
            match ctrl_message {
                RecordControlMessage::GetFrame => {
                    let mut frame: Option<Frame> = None;

                    if let Some(frame_rwl) = GLOBAL_FRAME.get() {
                        println!("!!!!!!!!!!! SENDING FRAME");
                        frame = Some(frame_rwl.read().await.clone());
                    } else {
                        #[cfg(env = "dev")]
                        {
                            use crate::image_generator::generate_random_image;
                            println!("SENDING GENERATED IMAGE");
                            let data = generate_random_image(GENERATE_FRAME_WIDTH);
                            frame = Some(Frame::new(data.0 as u32, data.1 as u32, data.2))
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
                        frame_tx.send(FrameResponse::NoFrame).await.unwrap();
                    }
                }
                RecordControlMessage::StopRecording => {
                    if let Some(vr) = video_recorder.as_ref() {
                        let _ = vr.stop();
                    }
                }
                RecordControlMessage::StartRecording => {
                    dbg!("START RECORDING!");
                    if let Some(vr) = video_recorder.as_ref() {
                        let _ = vr.start();
                    }
                }
            };
        }
    }
}
