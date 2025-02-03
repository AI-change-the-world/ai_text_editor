use std::sync::RwLock;

use crate::frb_generated::StreamSink;

#[derive(Debug)]
pub enum MessageType {
    Error,
    Success,
    Info,
}

pub static NORMAL_MESSAGE: RwLock<Option<StreamSink<(String, MessageType)>>> = RwLock::new(None);

pub fn send_message(message: String, r#type: MessageType) {
    if let Some(sink) = NORMAL_MESSAGE.read().unwrap().as_ref() {
        let _ = sink.add((message, r#type));
    }
}
