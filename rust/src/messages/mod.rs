use std::sync::RwLock;

use crate::frb_generated::StreamSink;

pub static NORMAL_MESSAGE: RwLock<Option<StreamSink<String>>> = RwLock::new(None);

pub fn send_message(message: String) {
    if let Some(sink) = NORMAL_MESSAGE.read().unwrap().as_ref() {
        let _ = sink.add(message);
    }
}
