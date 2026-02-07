use std::process::exit;

use chrono::{TimeDelta, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use websocket::{ClientBuilder, Message, OwnedMessage};

use crate::{
    config::CONFIG,
    screen_capture::{self, get_monitor, get_screenshot, img_to_png_base64},
};

pub fn connect_to_server_sync() {
    let mut client = ClientBuilder::new(CONFIG.api_websocket_url)
        .unwrap()
        .connect_insecure()
        .unwrap();

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
        // if last time is more than 1 second, make a screenshot and reset

        if let Some(sentinel_id) = sentinel_id
            && last_screenshot_time - Utc::now() > TimeDelta::seconds(1)
        {
            last_screenshot_time = Utc::now();

            let image = get_screenshot(&monitor);

            let base64 = img_to_png_base64(image);

            let ws_message = SentinelMessage {
                payload: SentinelPayload::Frame {
                    frames: vec![Frame {
                        sentinel_id: sentinel_id,
                        frame_id: Uuid::new_v4(),
                        data: base64,
                        index: frame_index,
                    }],
                },

                timestamp: Utc::now().timestamp(),
            };

            frame_index += 1;

            let _ =
                client.send_message(&Message::text(serde_json::to_string(&ws_message).unwrap()));
        }

        if let Ok(msg) = client.recv_message() {
            match msg {
                websocket::OwnedMessage::Text(msg) => {
                    match serde_json::from_str::<ServerMessage>(msg.as_str()) {
                        Ok(msg) => {
                            match msg.payload {
                                ServerPayload::RegistrationReject { reason } => {
                                    let _ = client.shutdown();
                                    panic!("REJECTED FROM THE SERVER BECAUSE OF: {}", reason);
                                }
                                ServerPayload::RegistrationAck { sentinel_id: id } => {
                                    sentinel_id = Some(id);
                                }
                            };
                        }
                        Err(_) => panic!("failed to parse message, for now panicing"),
                    }
                }
                websocket::OwnedMessage::Close(close_data) => {
                    panic!("websocket closed!");
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
