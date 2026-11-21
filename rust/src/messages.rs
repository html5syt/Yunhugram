//! 文本发送与历史记录，成功状态由服务端确认。
use crate::{
    engine::{Engine, required},
    network::{CoreError, Result},
    protocol::{MessageContent, MessageList, MessageListRequest, SendMessage, StatusResponse},
};
use prost::Message;
use reqwest::Method;
use serde_json::{Value, json};
impl Engine {
    pub async fn message_command(&mut self, kind: &str, args: &Value) -> Result<Value> {
        let chat_id = required(args, "chatId")?.to_owned();
        let chat_type = args["chatType"]
            .as_i64()
            .filter(|v| (1..=3).contains(v))
            .ok_or_else(|| CoreError::new("request", "聊天对象类别无效"))?
            as i32;
        match kind {
            "getMessages" => {
                let request = MessageListRequest {
                    msg_count: 30,
                    msg_id: args["before"].as_str().unwrap_or_default().into(),
                    chat_id,
                    chat_type,
                };
                let response: MessageList = self
                    .net
                    .protobuf(
                        "v1/msg/list-message",
                        &self.token,
                        Method::POST,
                        request.encode_to_vec(),
                    )
                    .await?;
                Ok(json!({"list":response.data,"hasMore":response.data.len()>=30}))
            }
            "sendMessage" => {
                let msg_id = uuid::Uuid::new_v4().simple().to_string();
                let request = SendMessage {
                    msg_id: msg_id.clone(),
                    chat_id,
                    chat_type,
                    content: Some(MessageContent {
                        text: required(args, "text")?.into(),
                        ..Default::default()
                    }),
                    content_type: 1,
                };
                let _: StatusResponse = self
                    .net
                    .protobuf(
                        "v1/msg/send-message",
                        &self.token,
                        Method::POST,
                        request.encode_to_vec(),
                    )
                    .await?;
                Ok(json!({"messageId":msg_id}))
            }
            _ => Err(CoreError::new("request", "未知的消息操作")),
        }
    }
}
