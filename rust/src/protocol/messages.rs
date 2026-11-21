//! 文本消息与历史记录协议；非文本内容保留类别，不伪装成文本。
use super::Status;
use prost::Message;
use serde::Serialize;
#[derive(Clone, PartialEq, Message, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MessageContent {
    #[prost(string, tag = "1")]
    pub text: String,
    #[prost(string, tag = "3")]
    pub image_url: String,
    #[prost(string, tag = "4")]
    pub file_name: String,
}
#[derive(Clone, PartialEq, Message, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Sender {
    #[prost(string, tag = "1")]
    pub chat_id: String,
    #[prost(int32, tag = "2")]
    pub chat_type: i32,
    #[prost(string, tag = "3")]
    pub name: String,
    #[prost(string, tag = "4")]
    pub avatar_url: String,
}
#[derive(Clone, PartialEq, Message, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MessageData {
    #[prost(string, tag = "1")]
    pub msg_id: String,
    #[prost(message, optional, tag = "2")]
    pub sender: Option<Sender>,
    #[prost(string, tag = "3")]
    pub direction: String,
    #[prost(int32, tag = "4")]
    pub content_type: i32,
    #[prost(message, optional, tag = "5")]
    pub content: Option<MessageContent>,
    #[prost(uint64, tag = "6")]
    pub send_timestamp_ms: u64,
    #[prost(uint64, tag = "8")]
    pub recall_timestamp: u64,
    #[prost(uint64, tag = "10")]
    pub msg_seq: u64,
}
#[derive(Clone, PartialEq, Message)]
pub struct MessageList {
    #[prost(message, optional, tag = "1")]
    pub status: Option<Status>,
    #[prost(message, repeated, tag = "2")]
    pub data: Vec<MessageData>,
    #[prost(int32, tag = "3")]
    pub total: i32,
}
#[derive(Clone, PartialEq, Message)]
pub struct MessageListRequest {
    #[prost(int32, tag = "2")]
    pub msg_count: i32,
    #[prost(string, tag = "3")]
    pub msg_id: String,
    #[prost(int32, tag = "4")]
    pub chat_type: i32,
    #[prost(string, tag = "5")]
    pub chat_id: String,
}
#[derive(Clone, PartialEq, Message)]
pub struct SendMessage {
    #[prost(string, tag = "2")]
    pub msg_id: String,
    #[prost(string, tag = "3")]
    pub chat_id: String,
    #[prost(int32, tag = "4")]
    pub chat_type: i32,
    #[prost(message, optional, tag = "5")]
    pub content: Option<MessageContent>,
    #[prost(int32, tag = "6")]
    pub content_type: i32,
}
/// 创建机器人使用客户端 Protobuf，而非机器人服务端接口。
#[derive(Clone, PartialEq, Message)]
pub struct CreateBot {
    #[prost(string, tag = "2")]
    pub name: String,
    #[prost(string, tag = "3")]
    pub introduction: String,
    #[prost(string, tag = "4")]
    pub avatar_url: String,
    #[prost(bool, tag = "5")]
    pub private: bool,
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn text_send_uses_verified_tags_and_type() {
        let msg = SendMessage {
            msg_id: "m".into(),
            chat_id: "c".into(),
            chat_type: 2,
            content: Some(MessageContent {
                text: "你好".into(),
                ..Default::default()
            }),
            content_type: 1,
        };
        let bytes = msg.encode_to_vec();
        assert_eq!(&bytes[..3], &[0x12, 1, b'm']);
        assert_eq!(
            SendMessage::decode(bytes.as_slice())
                .unwrap()
                .content
                .unwrap()
                .text,
            "你好"
        );
    }
}
