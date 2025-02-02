use flutter_rust_bridge::frb;

use crate::{frb_generated::StreamSink, messages::NORMAL_MESSAGE};

#[frb(sync)]
pub fn normal_message_stream(s: StreamSink<String>) -> anyhow::Result<()> {
    let mut stream = NORMAL_MESSAGE.write().unwrap();
    *stream = Some(s);
    anyhow::Ok(())
}
