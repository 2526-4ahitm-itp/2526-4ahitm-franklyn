use std::{sync::mpsc, time::Duration};

use tokio::{
    sync::mpsc::{Receiver, Sender},
    time::sleep,
};
use tracing::{error, warn};
use xcap::{Frame, Monitor, VideoRecorder};

use crate::{
    image_generator,
    video::{FrameEncoder, FrameProducer},
};

#[derive(Debug, Clone)]
pub(crate) enum RecorderCtrl {
    GetFrame,
    StartRecording,
    StopRecording,
}

#[derive(Debug, Clone)]
pub(crate) enum FrameResponse {
    Frame(xcap::Frame),
    NoFrame,
}

pub(crate) struct BasicRecorder<FC: FrameEncoder> {
    monitor: xcap::Monitor,

    sx: Option<std::sync::mpsc::Receiver<Frame>>,
    video_recorder: Option<VideoRecorder>,

    frame_encoder: FC,

    ctrl_rx: Receiver<RecorderCtrl>,
    data_tx: Sender<FrameResponse>,
}

impl<FC: FrameEncoder> BasicRecorder<FC> {
    async fn start_fake(mut ctrl_rx: Receiver<RecorderCtrl>, data_tx: Sender<FrameResponse>) {
        loop {
            match ctrl_rx.recv().await {
                Some(msg) => match msg {
                    RecorderCtrl::GetFrame => {
                        let (width, height, data) = image_generator::generate_random_image(192);

                        let frame = Frame::new(width as u32, height as u32, data);

                        data_tx.send(FrameResponse::Frame(frame)).await.unwrap();
                    }
                    _ => {}
                },
                None => {}
            }
        }
    }

    #[tracing::instrument(skip(ctrl_rx, data_tx, sx, video_recorder))]
    async fn start_real(
        mut ctrl_rx: Receiver<RecorderCtrl>,
        data_tx: Sender<FrameResponse>,
        sx: std::sync::mpsc::Receiver<Frame>,
        video_recorder: VideoRecorder,
        loop_duration: Duration,
    ) {
        loop {
            let mut frame: Option<Frame> = None;

            match sx.try_recv() {
                Ok(f) => frame = Some(f),
                Err(_) => {}
            }

            match ctrl_rx.try_recv() {
                Ok(msg) => match (msg, frame) {
                    (RecorderCtrl::GetFrame, Some(frame)) => {
                        data_tx.send(FrameResponse::Frame(frame)).await.unwrap();
                    }
                    (RecorderCtrl::StartRecording, _) => video_recorder.start().unwrap(),
                    (RecorderCtrl::StopRecording, _) => video_recorder.stop().unwrap(),
                    _ => {}
                },
                Err(_) => {}
            }

            sleep(loop_duration).await;
        }
    }
}

impl<FC: FrameEncoder> FrameProducer<FC> for BasicRecorder<FC> {
    type Ctrl = RecorderCtrl;
    type Data = FrameResponse;

    #[tracing::instrument(skip(ctrl_rx, data_tx))]
    fn new(ctrl_rx: Receiver<Self::Ctrl>, data_tx: Sender<Self::Data>, compute: FC) -> Self {
        let monitor = Monitor::from_point(100, 100).unwrap();

        match monitor.video_recorder() {
            Ok((video_recorder, sx)) => Self {
                monitor,
                sx: Some(sx),
                video_recorder: Some(video_recorder),
                ctrl_rx,
                data_tx,
            },
            Err(e) => {
                if cfg!(env = "dev") {
                    warn!("failed to grab video recorder: {:?}", e);
                    Self {
                        monitor,
                        sx: None,
                        video_recorder: None,

                        ctrl_rx,
                        data_tx,
                    }
                } else {
                    error!("failed to grab video recorder: {:?}", e);
                    std::process::exit(1);
                }
            }
        }
    }

    #[tracing::instrument]
    async fn start(self) {
        match (self.sx, self.video_recorder) {
            (Some(sx), Some(video_recorder)) => {
                let loop_duration = Duration::from_millis(
                    (1_000f32 / self.monitor.frequency().unwrap() / 2f32) as u64,
                );

                Self::start_real(
                    self.ctrl_rx,
                    self.data_tx,
                    sx,
                    video_recorder,
                    loop_duration,
                )
                .await
            }
            _ => Self::start_fake(self.ctrl_rx, self.data_tx).await,
        };
    }
}
