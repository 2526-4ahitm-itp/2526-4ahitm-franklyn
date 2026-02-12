use std::sync::{OnceLock, mpsc};

use base64::Engine;
use tokio::sync::{
    RwLock,
    mpsc::{Receiver, Sender},
};
use xcap::{
    Frame, Monitor, VideoRecorder,
    image::{ExtendedColorType, ImageBuffer, ImageEncoder, Rgba, codecs::png::PngEncoder},
};

#[derive(Debug, Clone)]
pub(crate) enum RecordControlMessage {
    GetFrame,
    StartRecording,
    StopRecording,
    Destroy,
}

pub(crate) enum FrameResponse {
    Frame(String),
    NoFrame,
}

static GLOBAL_FRAME: OnceLock<RwLock<xcap::Frame>> = OnceLock::new();

pub(crate) async fn start_screen_recording(
    mut ctrl_rx: Receiver<RecordControlMessage>,
    frame_tx: Sender<FrameResponse>,
) {
    let current_frame: Option<Frame> = None;

    let monitor = Monitor::from_point(100, 100).unwrap();

    dbg!("pre");

    let mut video_recorder: VideoRecorder;
    let mut sx: mpsc::Receiver<Frame>;

    loop {
        let res = monitor.video_recorder();

        if let Ok((vr, s)) = res {
            video_recorder = vr;
            sx = s;
            break;
        } else if let Err(e) = res {
            eprintln!("couldn't get video recorder");
            dbg!(e);
        }
    }

    dbg!("post");

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
                    let mut lock = GLOBAL_FRAME.get().unwrap().write().await;
                }
                _ => continue,
            }
        }
    });

    loop {
        if let Some(ctrl_message) = ctrl_rx.recv().await {
            match ctrl_message {
                RecordControlMessage::GetFrame => {
                    if let Some(frame_rwl) = GLOBAL_FRAME.get() {
                        let frame = frame_rwl.read().await;

                        // do processing before sending
                        let (w, h) = (frame.width, frame.height);
                        let mut out = Vec::new();
                        let _ = PngEncoder::new(&mut out)
                            .write_image(&frame.raw, w, h, ExtendedColorType::Rgba8)
                            .unwrap();

                        let base64 = base64::engine::general_purpose::STANDARD.encode(out);

                        let _ = frame_tx.send(FrameResponse::Frame(base64)).await;
                    } else {
                        eprintln!("sent no frame!");
                        let _ = frame_tx.send(FrameResponse::NoFrame).await;
                    }
                }
                RecordControlMessage::StopRecording => {
                    let _ = video_recorder.stop();
                }
                RecordControlMessage::StartRecording => {
                    dbg!("START RECORDING!");
                    let _ = video_recorder.start();
                }
                RecordControlMessage::Destroy => break,
            };
        }
    }
}

type OurImage = ImageBuffer<Rgba<u8>, Vec<u8>>;

pub(crate) fn get_monitor() -> Monitor {
    Monitor::from_point(100, 100).unwrap()
}

pub(crate) fn get_screenshot(monitor: &Monitor) -> OurImage {
    monitor.capture_image().unwrap()
}

pub(crate) fn img_to_png_base64(img: OurImage) -> String {
    let (w, h) = img.dimensions();
    let raw = img.as_raw();

    let mut out = Vec::new();
    let _ = PngEncoder::new(&mut out)
        .write_image(raw, w, h, ExtendedColorType::Rgba8)
        .unwrap();

    base64::engine::general_purpose::STANDARD.encode(out)
}
