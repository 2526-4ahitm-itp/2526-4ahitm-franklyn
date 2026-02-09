use std::{io::ErrorKind, thread, time::Duration};

use chrono::{TimeDelta, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use websocket::dataframe::{DataFrame, Opcode};
use websocket::{ClientBuilder, Message, OwnedMessage};

use crate::{
    config::CONFIG,
    screen_capture::{get_monitor, get_screenshot, img_to_png_base64},
};

pub fn connect_to_server_sync() {
    let mut client = ClientBuilder::new(CONFIG.api_websocket_url)
        .unwrap()
        .connect_insecure()
        .unwrap();

    // `recv_message()` is blocking by default, which prevents our loop from
    // doing periodic work (like taking screenshots). Switch to non-blocking and
    // treat "no data" as a normal state.
    let _ = client.set_nonblocking(true);

    let mut last_screenshot_time = Utc::now();

    let monitor = get_monitor();

    let mut frame_index = 1;

    // register

    let mut sentinel_id: Option<Uuid> = None;

    let register_message = SentinelMessage {
        timestamp: Utc::now().timestamp(),
        payload: SentinelPayload::Register,
    };

    let _ = client.send_message(&Message::text(
        serde_json::to_string(&register_message).unwrap(),
    ));

    loop {
        // If last time is more than 1 second, make a screenshot and reset.
        if let Some(sentinel_id) = sentinel_id
            && (Utc::now() - last_screenshot_time) > TimeDelta::seconds(1)
        {
            println!("sending frame: {}", frame_index);
            last_screenshot_time = Utc::now();

            let image = get_screenshot(&monitor);

            let base64 = img_to_png_base64(image);

            let ws_message = SentinelMessage {
                payload: SentinelPayload::Frame {
                    frames: vec![Frame {
                        sentinel_id,
                        frame_id: Uuid::new_v4(),
                        data: base64,
                        index: frame_index,
                    }],
                },

                timestamp: Utc::now().timestamp(),
            };

            frame_index += 1;

            let json = serde_json::to_string(&ws_message).unwrap();
            let payload = json.as_bytes();
            const MAX_FRAME_PAYLOAD_BYTES: usize = 32 * 1024;

            let mut offset = 0;
            let mut first = true;
            while offset < payload.len() {
                let end = (offset + MAX_FRAME_PAYLOAD_BYTES).min(payload.len());
                let finished = end == payload.len();
                let opcode = if first {
                    Opcode::Text
                } else {
                    Opcode::Continuation
                };
                first = false;

                let mut df = DataFrame::new(finished, opcode, payload[offset..end].to_vec());
                df.reserved = [false, false, false];
                let _ = client.send_dataframe(&df);
                offset = end;
            }
        }

        match client.recv_message() {
            Ok(msg) => {
                dbg!(&msg);
                match msg {
                    OwnedMessage::Text(msg) => {
                        match serde_json::from_str::<ServerMessage>(msg.as_str()) {
                            Ok(msg) => match msg.payload {
                                ServerPayload::RegistrationReject { reason } => {
                                    let _ = client.shutdown();
                                    panic!("REJECTED FROM THE SERVER BECAUSE OF: {}", reason);
                                }
                                ServerPayload::RegistrationAck { sentinel_id: id } => {
                                    sentinel_id = Some(id);
                                    dbg!(&sentinel_id);
                                }
                            },
                            Err(_) => panic!("failed to parse message, for now panicing"),
                        }
                    }
                    OwnedMessage::Close(_close_data) => {
                        panic!("websocket closed!");
                    }
                    _ => {}
                }
            }
            Err(err) => match err {
                websocket::WebSocketError::NoDataAvailable => {}
                websocket::WebSocketError::IoError(ref io)
                    if io.kind() == ErrorKind::WouldBlock || io.kind() == ErrorKind::TimedOut =>
                {
                    // Expected in non-blocking mode.
                }
                _ => {
                    // Preserve prior behavior of "fail loud" for unexpected errors.
                    panic!("websocket recv error: {err:?}");
                }
            },
        }

        // Avoid a hot loop while still keeping a responsive recv.
        thread::sleep(Duration::from_millis(10));
    }
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
