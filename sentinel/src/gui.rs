use iced::{
    Element, Task,
    futures::channel::mpsc::{Receiver, Sender},
};

pub enum CodeEvent {
    Online,
}

pub enum UiAction {
    JoinExam,
}

pub struct Gui {
    /// Receiver to update the user interface with values from the inside of the
    /// program like connection status, pin, etc.
    ui_rx: Receiver<CodeEvent>,

    /// Sender used to request data or trigger an action in the rust backend
    ui_tx: Sender<UiAction>,
}

enum GuiMessage {
    Hello,
    World,
}

impl Gui {
    pub fn run(ui_rx: Receiver<CodeEvent>, ui_tx: Sender<UiAction>) {
        iced::application(move || Gui { ui_rx, ui_tx }, Self::update, Self::view);
    }

    fn update(&mut self, message: GuiMessage) {
        todo!();
    }

    fn view(&self) -> Element<'_, GuiMessage> {
        todo!()
    }
}
