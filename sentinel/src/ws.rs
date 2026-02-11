use std::{io::ErrorKind, thread, time::Duration};

use chrono::{TimeDelta, Utc};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use tokio::select;
use tokio::sync::mpsc::{Receiver, Sender};
use tokio::time::{interval, sleep};
use tokio_tungstenite::connect_async;
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use uuid::Uuid;

use crate::screen_capture::RecordControlMessage;
use crate::{
    config::CONFIG,
    screen_capture::{get_monitor, get_screenshot, img_to_png_base64},
};

pub(crate) async fn connect_to_server_sync(
    ctrl_tx: Sender<RecordControlMessage>,
    mut frame_rx: Receiver<xcap::Frame>,
) {
    let request = CONFIG.api_websocket_url.into_client_request().unwrap();

    let (stream, _) = connect_async(request).await.unwrap();

    let (mut ws_write, mut ws_read) = stream.split();

    let mut pending_frame_request = false;
    let mut frame_index = 1;

    let mut frame_interval = interval(Duration::from_millis(500));

    let mut sentinel_id: Option<Uuid> = None;

    let register_message = SentinelMessage {
        timestamp: Utc::now().timestamp(),
        payload: SentinelPayload::Register,
    };

    let payload = serde_json::to_string(&register_message).unwrap();

    let _ = ws_write.send(Message::Text(payload.into())).await;

    loop {
        // If last time is more than 1 second, make a screenshot and reset.

        select! {
            Some( msg ) = ws_read.next() => {
                dbg!(&msg);
                if let Ok(msg) = msg {
                    match msg {
                        Message::Text(msg) => {
                            match serde_json::from_str::<ServerMessage>(msg.as_str()) {
                                Ok(msg) => match msg.payload {
                                    ServerPayload::RegistrationReject { reason } => {
                                        // shutdown server
                                        eprintln!("REJECTED FROM THE SERVER BECAUSE OF: {}", reason);
                                        break;
                                    }
                                    ServerPayload::RegistrationAck { sentinel_id: id } => {
                                        sentinel_id = Some(id);
                                        let _ =
                                            ctrl_tx.send(RecordControlMessage::StartRecording).await;
                                        dbg!(&sentinel_id);
                                    }
                                },
                                Err(_) => {
                                    eprintln!("failed to parse message, for now panicing");
                                    break;
                                }
                            }
                        }
                        Message::Close(_close_data) => {
                            eprintln!("websocket closed!");
                            break;
                        }
                        _ => {
                            eprintln!("Unhandled websocket message");
                            break;
                        }
                    }

                }
            },

            _ = frame_interval.tick() => {

                if !pending_frame_request {


                    let _ = ctrl_tx.send(RecordControlMessage::GetFrame).await;

                    pending_frame_request = true;

                }
            }

            Some(frame) = frame_rx.recv() => {

                pending_frame_request = false;

                let frame_payload = SentinelMessage {
                    timestamp: Utc::now().timestamp(),
                    payload: SentinelPayload::Frame {
                        frames: vec![Frame {
                            frame_id: Uuid::new_v4(),
                            sentinel_id: sentinel_id.unwrap(),
                            index: frame_index,
                            data: "asdasd".to_string()
                        }]
                    }
                };

            }
        };
        // Avoid a hot loop while still keeping a responsive recv.
    }

    let _ = ctrl_tx.send(RecordControlMessage::StopRecording).await;
}

#[derive(Serialize, Deserialize, Debug)]
pub struct SentinelMessage {
    #[serde(flatten)]
    pub payload: SentinelPayload,
    pub timestamp: i64,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ServerMessage {
    #[serde(flatten)]
    pub payload: ServerPayload,
    pub timestamp: i64,
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(tag = "type", content = "payload")]
pub enum SentinelPayload {
    #[serde(rename = "sentinel.register")]
    Register,

    #[serde(rename = "sentinel.frame")]
    Frame { frames: Vec<Frame> },
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(tag = "type", content = "payload")]
pub enum ServerPayload {
    #[serde(rename = "server.registration.ack")]
    #[serde(rename_all = "camelCase")]
    RegistrationAck { sentinel_id: Uuid },

    #[serde(rename = "server.registration.reject")]
    RegistrationReject { reason: String },
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Frame {
    /// UUID of the sentinel that the Frame belongs to
    pub sentinel_id: Uuid,
    /// UUID of the frame itself
    pub frame_id: Uuid,
    /// Index of the frame in the order it was created relative to other frames
    pub index: i64,
    /// Base64 encoded data of the image
    pub data: String,
}
