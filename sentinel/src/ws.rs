use serde::{Deserialize, Serialize};
use uuid::Uuid;
use websocket::{ClientBuilder, OwnedMessage};

use crate::config::CONFIG;

pub fn connect_to_server_sync() {
    let mut client = ClientBuilder::new(CONFIG.api_websocket_url)
        .unwrap()
        .connect_insecure()
        .unwrap();

    loop {
        if let Ok(msg) = client.recv_message() {
            match msg {
                websocket::OwnedMessage::Text(msg) => {
                    match serde_json::from_str::<SentinelMessage>(msg.as_str()) {
                        Ok(msg) => {
                            dbg!(&msg);
                        }
                        Err(_) => panic!("failed to parse message, for now panicing"),
                    }
                }
                websocket::OwnedMessage::Close(close_data) => {
                    eprintln!("websocket closed!");
                }
                _ => todo!(""),
            }
        }
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
