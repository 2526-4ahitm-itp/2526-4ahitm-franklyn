use std::{
    process::exit,
    sync::{OnceLock, mpsc},
};

use base64::Engine;
use tokio::{
    select,
    sync::{
        RwLock,
        mpsc::{Receiver, Sender, channel},
    },
};
use tracing::{debug, error, warn};
use xcap::{
    Frame, Monitor, VideoRecorder,
    image::{ExtendedColorType, ImageEncoder, codecs::png::PngEncoder},
};

use crate::video::{
    FrameProducer,
    recorder::{BasicRecorder, FrameResponse, RecorderCtrl},
};

#[cfg(env = "dev")]
static GENERATE_FRAME_WIDTH: usize = 192;

#[derive(Debug, Clone)]
pub(crate) enum RecordControlMessage {
    GetFrame,
}

#[derive(Debug, Clone)]
pub(crate) enum DataResponse {
    Data(String),
    NoFrame,
}

static GLOBAL_FRAME: OnceLock<RwLock<xcap::Frame>> = OnceLock::new();

#[tracing::instrument(skip(frame_tx, ctrl_rx))]
pub(crate) async fn start_screen_recording(
    mut ctrl_rx: Receiver<RecordControlMessage>,
    frame_tx: Sender<DataResponse>,
) {
    let monitor = Monitor::from_point(100, 100).unwrap();

    let (data_tx, data_rx) = channel::<FrameResponse>(10);
    let (record_tx, record_rx) = channel::<RecorderCtrl>(10);

    let basic_recorder = BasicRecorder::new(record_rx, data_tx);

    tokio::spawn(async move {
        basic_recorder.start().await;
    });

    let mut latest_frame: Option<Frame> = None;

    loop {
        select! {
            Some(frame) = data_rx.recv() => {
                match frame {
                    FrameResponse::Frame(frame) => {
                        // do compute on the frame and send to 
                    },
                    FrameResponse::NoFrame => todo!(),
                }
            }
            Some(ctrl_message) = ctrl_rx.recv() => {
                match ctrl_message {
                    // dumb forwarding until the frame compute is implemented
                    RecordControlMessage::GetFrame => {
                        record_tx.send(RecorderCtrl::GetFrame).await;
                    },
                }
            }
        }

        if let Some(ctrl_message) = ctrl_rx.recv().await {
            match ctrl_message {
                RecordControlMessage::GetFrame => {
                    let frame: Option<Frame>;

                    if let Some(frame_rwl) = GLOBAL_FRAME.get() {
                        frame = Some(frame_rwl.read().await.clone());
                    } else {
                        #[cfg(env = "dev")]
                        {
                            use crate::image_generator::generate_random_image;
                            let data = generate_random_image(GENERATE_FRAME_WIDTH);
                            frame = Some(Frame::new(data.0 as u32, data.1 as u32, data.2))
                        }
                        #[cfg(env = "prod")]
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
                        let _ = frame_tx.send(DataResponse::Data(base64)).await;
                    } else {
                        frame_tx.send(DataResponse::NoFrame).await.unwrap();
                    }
                }
                RecordControlMessage::StopRecording => {
                    debug!("stop recording");
                    if let Some(vr) = video_recorder.as_ref() {
                        let _ = vr.stop();
                    }
                }
                RecordControlMessage::StartRecording => {
                    debug!("start recording");
                    if let Some(vr) = video_recorder.as_ref() {
                        let _ = vr.start();
                    }
                }
            };
        }
    }
}
