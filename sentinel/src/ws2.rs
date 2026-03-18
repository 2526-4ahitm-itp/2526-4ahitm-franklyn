use base64::Engine;
use chrono::Utc;
use futures_util::{SinkExt, StreamExt};
use reqwest::header::AUTHORIZATION;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use tokio::select;
use tokio::sync::mpsc::Receiver;
use tokio::time::{self, Duration, Instant};
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::protocol::WebSocketConfig;
use tracing::{debug, error, info, warn};
use uuid::Uuid;

use crate::config::CONFIG;
use crate::recorder::{CaptureOutput, JpegBlob, Recorder};

static WEBSOCKET_MAX_FRAME_SIZE: usize = 2usize.pow(20);

#[tracing::instrument(skip_all)]
pub(crate) async fn connect_to_server_async(
    recorder: Recorder,
    mut capture_rx: Receiver<CaptureOutput>,
    jwt: String,
) {
    let protocol_prefix = if cfg!(env = "prod") { "wss:" } else { "ws:" };
    let uri_string = format!("{}{}/ws/sentinel", protocol_prefix, CONFIG.api_url);

    info!("connecting to \"{}\"", uri_string);

    let mut request = match uri_string.into_client_request() {
        Ok(request) => request,
        Err(err) => {
            error!(error = %err, "failed to build websocket request");
            recorder.stop();
            return;
        }
    };

    let auth_header = match format!("Bearer {jwt}").parse() {
        Ok(header) => header,
        Err(err) => {
            error!(error = %err, "failed to build authorization header");
            recorder.stop();
            return;
        }
    };
    request.headers_mut().insert(AUTHORIZATION, auth_header);

    let config = WebSocketConfig::default().max_frame_size(Some(WEBSOCKET_MAX_FRAME_SIZE));

    let connect_result = {
        #[cfg(env = "dev")]
        {
            use tokio_tungstenite::connect_async_with_config;
            connect_async_with_config(request, Some(config), false).await
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
        }
    };

    let (stream, _) = match connect_result {
        Ok(stream) => stream,
        Err(err) => {
            error!(error = %err, "failed to connect websocket");
            recorder.stop();
            return;
        }
    };

    let (mut ws_write, mut ws_read) = stream.split();

    let register_payload = match serde_json::to_string(&SentinelMessage {
        timestamp: Utc::now().timestamp(),
        payload: SentinelPayload::Register,
    }) {
        Ok(payload) => payload,
        Err(err) => {
            error!(error = %err, "failed to serialize registration payload");
            recorder.stop();
            return;
        }
    };

    if ws_write
        .send(Message::Text(register_payload.into()))
        .await
        .is_err()
    {
        error!("failed to send registration payload");
        recorder.stop();
        return;
    }

    info!("registration payload sent, waiting for ack");

    let mut sentinel_id: Option<Uuid> = None;
    let mut last_capture_frame_at = Instant::now();
    let mut stall_check = time::interval(Duration::from_secs(3));

    loop {
        select! {
            output = capture_rx.recv() => {
                match output {
                    Some(CaptureOutput::Jpeg(blob)) => {
                        last_capture_frame_at = Instant::now();

                        if let Some(id) = sentinel_id {
                            let frame_index = blob.sequence;
                            let frame_message = build_frame_message(id, blob);
                            match serde_json::to_string(&frame_message) {
                                Ok(payload) => {
                                    if let Err(err) = ws_write.send(Message::Text(payload.into())).await {
                                        error!(error = %err, frame_index, "failed to send jpeg frame to websocket");
                                        break;
                                    }
                                }
                                Err(err) => {
                                    error!(error = %err, frame_index, "failed to serialize frame payload");
                                }
                            }
                        } else {
                            warn!(frame_index = blob.sequence, "dropping captured frame before registration ack");
                        }
                    }
                    None => {
                        error!("capture channel closed; recorder stopped producing frames");
                        break;
                    }
                }
            }

            ws_msg = ws_read.next() => {
                match ws_msg {
                    Some(Ok(msg)) => match msg {
                        Message::Text(text) => {
                            match parse_server_message(text.as_str()) {
                                ParsedServerMessage::RegistrationAck { sentinel } => {
                                    sentinel_id = Some(sentinel);
                                    info!(sentinel_id = %sentinel, "registration acknowledged; streaming frames");
                                }
                                ParsedServerMessage::RegistrationReject { reason } => {
                                    error!(reason, "server rejected registration");
                                    break;
                                }
                                ParsedServerMessage::Unknown => {
                                    debug!("ignoring unsupported server message type");
                                }
                            }
                        }
                        Message::Close(frame) => {
                            info!(?frame, "websocket close frame received");
                            break;
                        }
                        Message::Binary(_) => {
                            warn!("ignoring unexpected binary websocket message");
                        }
                        _ => {}
                    },
                    Some(Err(err)) => {
                        error!(error = %err, "websocket read error");
                        break;
                    }
                    None => {
                        warn!("websocket stream ended");
                        break;
                    }
                }
            }

            _ = stall_check.tick() => {
                let stalled_for = Instant::now().duration_since(last_capture_frame_at);
                if stalled_for >= Duration::from_secs(3) {
                    warn!(
                        stalled_ms = stalled_for.as_millis(),
                        "no frames received from recorder output channel"
                    );
                }
            }

            else => {
                warn!("event loop ended because all select branches closed");
                break;
            },
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
