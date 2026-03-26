use base64::Engine;
use base64::engine::general_purpose;
use chrono::Utc;
use futures_util::stream::SplitSink;
use futures_util::{SinkExt, StreamExt};
use reqwest::header::AUTHORIZATION;
use serde::{Deserialize, Serialize};
use tokio::net::TcpStream;
use tokio::select;
use tokio::sync::mpsc::Receiver;
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::protocol::WebSocketConfig;
use tokio_tungstenite::{MaybeTlsStream, WebSocketStream};
use tracing::{debug, error, info};
use uuid::Uuid;

use crate::config::CONFIG;
use crate::recorder::{CaptureOutput, Recorder};

static WEBSOCKET_MAX_FRAME_SIZE: usize = 2usize.pow(16) - 1;

#[tracing::instrument(skip_all)]
pub(crate) async fn connect_to_server_async(
    recorder: Recorder,
    mut capture_rx: Receiver<CaptureOutput>,
    jwt: String,
) {
    let protocol_prefix = if cfg!(env = "prod") { "wss:" } else { "ws:" };
    let uri_string = format!("{}{}/ws/sentinel", protocol_prefix, CONFIG.api_url);

    info!("connecting to \"{}\"", uri_string);

    let mut request = uri_string.into_client_request().unwrap();

    request
        .headers_mut()
        .insert(AUTHORIZATION, format!("Bearer {jwt}").parse().unwrap());

    let config = WebSocketConfig::default().max_frame_size(Some(WEBSOCKET_MAX_FRAME_SIZE));

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

    let mut frame_index = 1;

    let mut sentinel_id: Option<Uuid> = None;

    let register_message = SentinelMessage {
        timestamp: Utc::now().timestamp(),
        payload: SentinelPayload::Register,
    };

    let payload = serde_json::to_string(&register_message).unwrap();

    let _ = ws_write.send(Message::Text(payload.into())).await;

    loop {
        select! {

            Some(CaptureOutput::Jpeg(jpeg_blob)) = capture_rx.recv() => {
                if let Some(sentinel_id) = sentinel_id {

                    let jpeg_base64 = general_purpose::STANDARD.encode(&jpeg_blob.data);

                    let frame_message = SentinelMessage {
                        timestamp: Utc::now().timestamp(),
                        payload: SentinelPayload::Frame {
                            frames: vec![Frame {
                                frame_id: Uuid::new_v4(),
                                sentinel_id,
                                index: frame_index,
                                data: jpeg_base64
                            }]
                        }
                    };


                    let frame_payload = serde_json::to_string(&frame_message).unwrap();
                    // send_large_string(&mut ws_write, frame_payload).await.unwrap();
                    ws_write.send(Message::Text(frame_payload.into())).await.unwrap();

                    frame_index += 1;
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
                                        info!("sending frames as sentinel: {}", id);
                                    }
                                    ServerPayload::Resolution{max_side_px} => {
                                        recorder.set_quality(((max_side_px as f32 / 1000.0) as u32).max(100));
                                        info!("setting maximum pixel size to '{max_side_px}'");
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

        };
        // Avoid a hot loop while still keeping a responsive recv.
    }

    recorder.stop();
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

    #[serde(rename = "server.set-resolution")]
    #[serde(rename_all = "camelCase")]
    Resolution { max_side_px: u32 },
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
