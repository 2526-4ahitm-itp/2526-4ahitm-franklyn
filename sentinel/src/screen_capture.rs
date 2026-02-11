use base64::Engine;
use tokio::{
    select,
    sync::mpsc::{Receiver, Sender},
};
use xcap::{
    Frame, Monitor,
    image::{ExtendedColorType, ImageBuffer, ImageEncoder, Rgba, codecs::png::PngEncoder},
};

#[derive(Debug, Clone)]
pub(crate) enum RecordControlMessage {
    GetFrame,
    StartRecording,
    StopRecording,
    Destroy,
}

pub(crate) async fn start_screen_recording(
    mut ctrl_rx: Receiver<RecordControlMessage>,
    frame_tx: Sender<Frame>,
) {
    let mut current_frame: Option<Frame> = None;

    let monitor = Monitor::from_point(100, 100).unwrap();

    let (video_recorder, sx) = monitor.video_recorder().unwrap();

    tokio::spawn(async move {
        loop {
            match sx.recv() {
                Ok(frame) => {
                    println!("frame: {:?}", frame.width);
                }
                _ => continue,
            }
        }
    });

    loop {
        if let Some(ctrl_message) = ctrl_rx.recv().await {
            match ctrl_message {
                RecordControlMessage::GetFrame => {
                    if let Some(frame) = current_frame.clone() {
                        dbg!(&frame);
                        // do processing before sending
                        let _ = frame_tx.send(frame).await;
                    };
                }
                RecordControlMessage::StopRecording => {
                    let _ = video_recorder.stop();
                }
                RecordControlMessage::StartRecording => {
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
