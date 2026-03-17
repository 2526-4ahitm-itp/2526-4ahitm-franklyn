use base64::Engine;
use chrono::Utc;
use futures_util::{SinkExt, StreamExt};
use reqwest::header::AUTHORIZATION;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use tokio::select;
use tokio::sync::mpsc::Receiver;
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::protocol::WebSocketConfig;
use tracing::{error, info, warn};
use uuid::Uuid;

use crate::config::CONFIG;
use crate::recorder::{CaptureOutput, JpegBlob, Recorder};

static WEBSOCKET_MAX_FRAME_SIZE: usize = 2usize.pow(20);

#[tracing::instrument(skip(recorder, capture_rx, jwt))]
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

    let register_payload = serde_json::to_string(&SentinelMessage {
        timestamp: Utc::now().timestamp(),
        payload: SentinelPayload::Register,
    })
    .unwrap();

    if ws_write
        .send(Message::Text(register_payload.into()))
        .await
        .is_err()
    {
        recorder.stop();
        return;
    }

    let mut sentinel_id: Option<Uuid> = None;

    loop {
        select! {
            Some(output) = capture_rx.recv() => {
                info!("received something");
                match output {
                    CaptureOutput::Jpeg(blob) => {
                        if let Some(id) = sentinel_id {

                            let frame_message = build_frame_message(id, blob);
                            let payload = serde_json::to_string(&frame_message).unwrap();
                            if ws_write.send(Message::Text(payload.into())).await.is_err() {
                                break;
                            }
                        }
                    }
                }
            }

            Some(msg) = ws_read.next() => {
                let Ok(msg) = msg else { break; };
                match msg {
                    Message::Text(text) => {
                        match parse_server_message(text.as_str()) {
                            ParsedServerMessage::RegistrationAck { sentinel } => {
                                sentinel_id = Some(sentinel);
                                info!("sending jpeg blobs as sentinel: {}", sentinel);
                            }
                            ParsedServerMessage::RegistrationReject { reason } => {
                                error!("got rejected from the server because of: {}", reason);
                                break;
                            }
                            ParsedServerMessage::KeyframeRequest => {
                                recorder.force_keyframe();
                            }
                            ParsedServerMessage::FpsChange { framerate } => {
                                recorder.set_fps(framerate);
                            }
                            ParsedServerMessage::SetResolution { max_side_px } => {
                                warn!(
                                    "server requested max_side_px={}, but runtime resolution changes are not supported yet",
                                    max_side_px
                                );
                            }
                            ParsedServerMessage::Unknown => {}
                        }
                    }
                    Message::Close(_) => break,
                    Message::Binary(_) => {}
                    _ => {}
                }
            }

            else => break,
        }
    }

    warn!("websocket closed, stopping recorder");
    recorder.stop();
}

fn build_frame_message(sentinel_id: Uuid, blob: JpegBlob) -> SentinelMessage {
    let data = base64::engine::general_purpose::STANDARD.encode(blob.data);
    SentinelMessage {
        timestamp: Utc::now().timestamp(),
        payload: SentinelPayload::Frame {
            frames: vec![Frame {
                sentinel_id,
                frame_id: Uuid::new_v4(),
                index: blob.sequence as i64,
                data,
            }],
        },
    }
}

enum ParsedServerMessage {
    RegistrationAck { sentinel: Uuid },
    RegistrationReject { reason: String },
    KeyframeRequest,
    FpsChange { framerate: f32 },
    SetResolution { max_side_px: u32 },
    Unknown,
}

fn parse_server_message(raw: &str) -> ParsedServerMessage {
    let Ok(value) = serde_json::from_str::<Value>(raw) else {
        return ParsedServerMessage::Unknown;
    };

    let Some(msg_type) = value.get("type").and_then(Value::as_str) else {
        return ParsedServerMessage::Unknown;
    };

    match msg_type {
        "server.registration.ack" => {
            let sentinel_str = value
                .get("payload")
                .and_then(|p| p.get("sentinelId"))
                .and_then(Value::as_str);

            if let Some(id) = sentinel_str.and_then(|s| Uuid::parse_str(s).ok()) {
                ParsedServerMessage::RegistrationAck { sentinel: id }
            } else {
                ParsedServerMessage::Unknown
            }
        }
        "server.registration.reject" => {
            let reason = value
                .get("payload")
                .and_then(|p| p.get("reason"))
                .and_then(Value::as_str)
                .unwrap_or("unknown reason")
                .to_string();
            ParsedServerMessage::RegistrationReject { reason }
        }
        "keyframe.request" => ParsedServerMessage::KeyframeRequest,
        "fps.change" => {
            let framerate = value
                .get("payload")
                .and_then(|p| p.get("framerate"))
                .or_else(|| value.get("framerate"))
                .and_then(Value::as_f64)
                .unwrap_or(5.0) as f32;
            ParsedServerMessage::FpsChange { framerate }
        }
        "server.set-resolution" => {
            let max_side_px = value
                .get("payload")
                .and_then(|p| p.get("maxSidePx"))
                .and_then(Value::as_u64)
                .unwrap_or(0) as u32;
            ParsedServerMessage::SetResolution { max_side_px }
        }
        _ => ParsedServerMessage::Unknown,
    }
}

#[derive(Serialize, Debug)]
pub struct SentinelMessage {
    #[serde(flatten)]
    pub payload: SentinelPayload,
    pub timestamp: i64,
}

#[derive(Serialize, Debug)]
#[serde(tag = "type", content = "payload")]
pub enum SentinelPayload {
    #[serde(rename = "sentinel.register")]
    Register,

    #[serde(rename = "sentinel.frame")]
    Frame { frames: Vec<Frame> },
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Frame {
    pub sentinel_id: Uuid,
    pub frame_id: Uuid,
    pub index: i64,
    pub data: String,
}
