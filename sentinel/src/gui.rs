use std::marker::PhantomData;

use iced::{
    Element,
    futures::channel::mpsc::{Receiver, Sender},
    widget::{Button, button, text},
};

pub enum CodeEvent {
    Online,
}

pub enum UiEvent {
    JoinExam,
}

pub struct Gui {}

enum GuiMessage {
    Hello,
    World,
}

impl Gui {
    pub fn run(ui_rx: Receiver<CodeEvent>, ui_tx: Sender<UiEvent>) {
        iced::run(update, view).unwrap();
    }
}

fn view(counter: &u32) -> Element<'_, GuiMessage> {
    text(counter).into()
}

fn update(counter: &mut u32, message: GuiMessage) {
    *counter += 1;
}
