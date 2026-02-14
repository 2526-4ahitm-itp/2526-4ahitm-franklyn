use tokio::sync::mpsc::{Receiver, Sender};

pub(crate) mod recorder;

pub(crate) trait FrameProducer<FC: FrameEncoder> {
    type Ctrl: Send;
    type Data: Send;

    async fn request_frame() -> Option<Box<Self::Data>>;
}

pub(crate) trait FrameEncoder {
    type In;
    type Out;

    fn compute(frame: Self::In) -> Self::Out;
}
