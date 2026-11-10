use iced::{
    Application, Task,
    application::{UpdateFn, ViewFn},
    widget::{button, column, text, text_input},
};
use uuid::Uuid;

#[derive(Clone, Debug)]
pub enum State {
    Login { url: String, token: Uuid },
    EnterPin(String),
    Running(Uuid),
}

#[derive(Debug, Clone)]
pub enum Message {
    ChangePin(String),
}

#[derive(Debug)]
pub struct GraphicsApplication {
    pub state: State,
}

impl GraphicsApplication {
    pub fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::ChangePin(pin) => {
                if let State::EnterPin(_) = self.state {
                    self.state = State::EnterPin(pin);
                    Task::none()
                } else {
                    Task::none()
                }
            }
        }
    }

    pub fn view(&self) -> iced::Element<'_, Message> {
        match &self.state {
            State::Login { url, token } => column![text(url), text(token.to_string())].into(),
            State::EnterPin(pin) => column![
                text_input("Enter your 4-digit pin", &pin),
                button("Join now")
            ]
            .into(),
            State::Running(uuid) => column![text(format!("Running as user {uuid}"))].into(),
        }
    }
}
