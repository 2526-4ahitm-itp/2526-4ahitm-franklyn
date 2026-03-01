use std::time::Duration;

use chrono::Utc;
use futures_util::stream::SplitSink;
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use tokio::net::TcpStream;
use tokio::select;
use tokio::sync::mpsc::{Receiver, Sender};
use tokio::time::interval;
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::protocol::WebSocketConfig;
use tokio_tungstenite::{MaybeTlsStream, WebSocketStream};
use tracing::{debug, error, info, warn};
use uuid::Uuid;

use crate::config::CONFIG;
use crate::screen_capture::FrameResponse;
use crate::screen_capture::RecordControlMessage;

static WEBSOCKET_MAX_FRAME_SIZE: usize = 2usize.pow(16) - 1;
static IMAGE_FRAME_RATE_MILLIS: u64 = 500;

#[tracing::instrument(skip(ctrl_tx, frame_rx))]
pub(crate) async fn connect_to_server_async(
    ctrl_tx: Sender<RecordControlMessage>,
    mut frame_rx: Receiver<FrameResponse>,
) {
    let protocol_prefix = if cfg!(env = "prod") { "wss:" } else { "ws:" };
    let url = format!("{}{}/ws/sentinel", protocol_prefix, CONFIG.api_url);

    let config = WebSocketConfig::default().max_frame_size(Some(WEBSOCKET_MAX_FRAME_SIZE));

    info!("connecting to \"{}\"", url);
    let request = url.into_client_request().unwrap();

    let (stream, _) = {
        #[cfg(env = "dev")]
        {
            use tokio_tungstenite::connect_async_with_config;

            connect_async_with_config(request, Some(config), false)
                .await
                .unwrap()
        }

        #[cfg(env = "prod")]
        {
            use native_tls::TlsConnector;
            use tokio_tungstenite::{Connector, connect_async_tls_with_config};

            connect_async_tls_with_config(
                request,
                Some(config),
                false,
                Some(Connector::NativeTls(TlsConnector::new().unwrap())),
            )
            .await
            .unwrap()
        }
    };

    let (mut ws_write, mut ws_read) = stream.split();

    let mut pending_frame_request = false;
    let mut frame_index = 1;

    let mut frame_interval = interval(Duration::from_millis(IMAGE_FRAME_RATE_MILLIS));

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

            Some(frame_response) = frame_rx.recv() => {

                info!("RECEIVED A FRAME FROM FRAMERX================");
                        pending_frame_request = false;

                if let FrameResponse::Frame(frame) = frame_response {

                    if let Some(sentinel_id) = sentinel_id {

                        let frame_message = SentinelMessage {
                            timestamp: Utc::now().timestamp(),
                            payload: SentinelPayload::Frame {
                                frames: vec![Frame {
                                    frame_id: Uuid::new_v4(),
                                    sentinel_id: sentinel_id,
                                    index: frame_index,
                                    data: frame
                                }]
                            }
                        };


                        let frame_payload = serde_json::to_string(&frame_message).unwrap();
                        // send_large_string(&mut ws_write, frame_payload).await.unwrap();
                        ws_write.send(Message::Text(frame_payload.into())).await.unwrap();

                        frame_index += 1;
                    } else {
                        warn!("not sending frames because sentinel id is still none");
                    }
                }
            }

            Some( msg ) = ws_read.next() => {
                if let Ok(msg) = msg {
                    match msg {
                        Message::Text(msg) => {
                            match serde_json::from_str::<ServerMessage>(msg.as_str()) {
                                Ok(msg) => match msg.payload {
                                    ServerPayload::RegistrationReject { reason } => {
                                        // shutdown server
                                        error!("got rejected from the server because of: {}", reason);
                                        break;
                                    }
                                    ServerPayload::RegistrationAck { sentinel_id: id } => {
                                        sentinel_id = Some(id);
                                        let _ =
                                            ctrl_tx.send(RecordControlMessage::StartRecording).await;
                                        info!("sending frames as sentinel: {}", id);
                                    }
                                },
                                Err(e) => {
                                    error!("failed to parse message: {}", e);
                                    break;
                                }
                            }
                        }
                        Message::Close(_close_data) => {
                            error!("websocket closed!");
                            break;
                        }
                        _ => {
                            error!("Unhandled websocket message");
                            break;
                        }
                    }

                }
            },

            _ = frame_interval.tick() => {
                info!("CALLING GET FRAME");
                if !pending_frame_request {
                    info!("REQUESTING A FRAME----");
                    let _ = ctrl_tx.send(RecordControlMessage::GetFrame).await;
                    pending_frame_request = true;
                } else {
                    info!("BUT IS NONE")
                }
            }

        };
        // Avoid a hot loop while still keeping a responsive recv.
    }

    let _ = ctrl_tx.send(RecordControlMessage::StopRecording).await;
}

async fn send_large_string(
    ws_write: &mut SplitSink<WebSocketStream<MaybeTlsStream<TcpStream>>, Message>,
    data: String,
) -> Result<(), tokio_tungstenite::tungstenite::Error> {
    use tokio_tungstenite::tungstenite::Message;
    use tokio_tungstenite::tungstenite::protocol::frame::{
        Frame, coding::Data as OpData, coding::OpCode,
    };

    let bytes = data.into_bytes();
    let chunks: Vec<&[u8]> = bytes.chunks(WEBSOCKET_MAX_FRAME_SIZE).collect();
    let total = chunks.len();
    debug!("sending large websocket message as multiple: {}", total);
    for (i, chunk) in chunks.iter().enumerate() {
        let is_first = i == 0;
        let is_last = i == total - 1;
        let opcode = if is_first {
            OpCode::Data(OpData::Text) // first frame: Text opcode
        } else {
            OpCode::Data(OpData::Continue) // subsequent frames: Continue opcode
        };
        let frame = Frame::message(chunk.to_vec(), opcode, is_last);
        ws_write.send(Message::Frame(frame)).await?;
    }
    Ok(())
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
