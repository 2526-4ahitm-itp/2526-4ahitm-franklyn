use anyhow::anyhow;
use anyhow::{Context, Ok, bail};
use chrono::Utc;
use futures_util::stream::{Next, SplitSink};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use tokio::net::TcpStream;
use tokio::select;
use tokio::sync::watch;
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::{MaybeTlsStream, WebSocketStream};
use tracing::{debug, error, info, instrument};
use uuid::Uuid;

use crate::config::CONFIG;
use crate::recorder_v3::{JPegBase64, Recorder};

static WEBSOCKET_MAX_FRAME_SIZE: usize = 2usize.pow(16) - 1;

#[tracing::instrument(skip_all)]
pub(crate) async fn connect_to_server_async(
    recorder: Recorder,
    mut capture_rx: watch::Receiver<Option<JPegBase64>>,
    jwt: String,
    pin: u32,
) -> anyhow::Result<()> {
    let protocol_prefix = if cfg!(not(debug_assertions)) {
        "wss://"
    } else {
        "ws://"
    };
    let uri_string = format!("{}{}/ws/sentinel", protocol_prefix, CONFIG.api_url);

    info!("connecting to \"{}\"", uri_string);

    let request = uri_string.into_client_request()?;

    let (stream, _) = {
        #[cfg(debug_assertions)]
        {
            use tokio_tungstenite::connect_async_with_config;

            connect_async_with_config(request, None, false)
                .await
                .context("websocket connection failed")?
        }

        #[cfg(not(debug_assertions))]
        {
            use native_tls::TlsConnector;
            use tokio_tungstenite::{Connector, connect_async_tls_with_config};

            connect_async_tls_with_config(
                request,
                None,
                false,
                Some(Connector::NativeTls(TlsConnector::new()?)),
            )
            .await
            .context("websocket connection failed (tls)")?
        }
    };

    let (mut ws_write, mut ws_read) = stream.split();

    let mut frame_index: u32 = 1;

    let mut sentinel_id: Option<Uuid> = None;

    let register_message = SentinelMessage {
        timestamp: Utc::now().timestamp(),
        payload: SentinelPayload::Register { pin, auth: jwt },
    };

    let payload = serde_json::to_string(&register_message).unwrap();

    ws_write.send(Message::Text(payload.into())).await?;

    let res: anyhow::Result<()> = loop {
        select! {
            Result::Ok(_) = capture_rx.changed() => {
                if let Err(err) = handle_frame(
                    &mut capture_rx,
                    &mut ws_write,
                    &sentinel_id,
                    &mut frame_index,
                ).await.context("frame handling failed") {
                    break Err(err);
                }
            }

            response = ws_read.next() => {
                match response {
                    Some(Result::Ok(msg)) => {
                       match handle_message(msg, &mut sentinel_id).await {
                           Result::Ok(_) => {}
                           Result::Err(err) => break Err(err)
                       }
                    }

                    Some(Err(err)) => break Err(err.into()),
                    None => break Err(anyhow!("websocket stream ended"))
                };
            }

        };
    };

    if let Err(err) = recorder.stop().await {
        error!(
            { error = &*err as &dyn std::error::Error },
            "failed to stop recorder"
        )
    }

    res
}

/// Handles a WebSocket Message from the server, if the sentinel_id was updated
/// or sent it is returned as `Ok(Uuid)`
#[instrument]
async fn handle_message(msg: Message, sentinel_id: &mut Option<Uuid>) -> anyhow::Result<()> {
    match msg {
        Message::Text(msg) => {
            let payload = serde_json::from_str::<ServerMessage>(msg.as_str())?;
            debug!(
                "websocket message received at {}: {:?}",
                payload.timestamp, payload.payload
            );

            match payload.payload {
                ServerPayload::RegistrationReject { reason } => {
                    bail!("got rejected from the server because of: {}", reason);
                }
                ServerPayload::RegistrationAck { sentinel_id: id } => {
                    info!("received sentinel_id, now sending as {}", id);
                    *sentinel_id = Some(id);
                    Ok(())
                }
                ServerPayload::Resolution { max_side_px: _ } => Ok(()),
            }
        }
        Message::Close(close_data) => {
            bail!("websocket closed: {:?}", close_data)
        }
        _ => {
            error!("Unhandled websocket message");
            Ok(())
        }
    }
}

#[instrument(skip(capture_rx))]
async fn handle_frame(
    capture_rx: &mut watch::Receiver<Option<JPegBase64>>,
    ws_write: &mut SplitSink<WebSocketStream<MaybeTlsStream<TcpStream>>, Message>,
    sentinel_id: &Option<Uuid>,
    frame_index: &mut u32,
) -> anyhow::Result<()> {
    if let Some(sentinel_id) = &sentinel_id {
        let frame = capture_rx.borrow_and_update().clone();

        if let Some(jpeg) = frame {
            let frame_message = SentinelMessage {
                timestamp: Utc::now().timestamp(),
                payload: SentinelPayload::Frame {
                    frames: vec![Frame {
                        frame_id: Uuid::new_v4(),
                        sentinel_id: *sentinel_id,
                        index: *frame_index as i64,
                        data: jpeg.data,
                    }],
                },
            };

            let frame_payload = serde_json::to_string(&frame_message)?;
            ws_write.send(Message::Text(frame_payload.into())).await?;

            *frame_index += 1;
        };
    }
    Ok(())
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
    Result::Ok(())
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
    Register { pin: u32, auth: String },

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
