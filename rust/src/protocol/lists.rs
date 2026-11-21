//! 对话与通讯录协议。
use super::Status;
use prost::Message;
use serde::Serialize;
#[derive(Clone, PartialEq, Message)]
pub struct ListRequest {
    #[prost(string, tag = "2")]
    pub md5: String,
}
#[derive(Clone, PartialEq, Message)]
pub struct ConversationResponse {
    #[prost(message, optional, tag = "1")]
    pub status: Option<Status>,
    #[prost(message, repeated, tag = "2")]
    pub data: Vec<Conversation>,
    #[prost(int32, tag = "3")]
    pub total: i32,
    #[prost(string, tag = "4")]
    pub md5: String,
}
#[derive(Clone, PartialEq, Message, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Conversation {
    #[prost(string, tag = "1")]
    pub chat_id: String,
    #[prost(int32, tag = "2")]
    pub chat_type: i32,
    #[prost(string, tag = "3")]
    pub remark: String,
    #[prost(string, tag = "4")]
    pub chat_content: String,
    #[prost(uint64, tag = "5")]
    pub timestamp_ms: u64,
    #[prost(int32, tag = "6")]
    pub unread_msg: i32,
    #[prost(bool, tag = "7")]
    pub at: bool,
    #[prost(string, tag = "9")]
    pub avatar_url: String,
    #[prost(bool, tag = "11")]
    pub do_not_disturb: bool,
    #[prost(uint64, tag = "12")]
    pub send_timestamp: u64,
    #[prost(string, tag = "15")]
    pub name: String,
}
#[derive(Clone, PartialEq, Message)]
pub struct ContactResponse {
    #[prost(message, optional, tag = "1")]
    pub status: Option<Status>,
    #[prost(message, repeated, tag = "2")]
    pub data: Vec<ContactGroup>,
    #[prost(string, tag = "3")]
    pub md5: String,
}
#[derive(Clone, PartialEq, Message, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ContactGroup {
    #[prost(string, tag = "1")]
    pub list_name: String,
    #[prost(message, repeated, tag = "2")]
    pub data: Vec<Contact>,
    #[prost(int32, tag = "3")]
    pub chat_type: i32,
}
#[derive(Clone, PartialEq, Message, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Contact {
    #[prost(string, tag = "1")]
    pub chat_id: String,
    #[prost(string, tag = "2")]
    pub remark: String,
    #[prost(string, tag = "3")]
    pub avatar_url: String,
    #[prost(int32, tag = "4")]
    pub permission_level: i32,
    #[prost(bool, tag = "5")]
    pub no_disturb: bool,
    #[prost(string, tag = "8")]
    pub name: String,
}
