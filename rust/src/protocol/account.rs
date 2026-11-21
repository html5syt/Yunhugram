//! 客户端 Protobuf 字段，依据 yhchatAPI/full.proto 的相同标签。
use prost::Message;
use serde::Serialize;

#[derive(Clone, PartialEq, Message, Serialize)]
pub struct Status {
    #[prost(uint64, tag = "1")]
    pub request_id: u64,
    #[prost(uint64, tag = "2")]
    pub code: u64,
    #[prost(string, tag = "3")]
    pub msg: String,
}
#[derive(Clone, PartialEq, Message)]
pub struct StatusResponse {
    #[prost(message, optional, tag = "1")]
    pub status: Option<Status>,
}
#[derive(Clone, PartialEq, Message)]
pub struct UserResponse {
    #[prost(message, optional, tag = "1")]
    pub status: Option<Status>,
    #[prost(message, optional, tag = "2")]
    pub data: Option<User>,
}
#[derive(Clone, PartialEq, Message, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct User {
    #[prost(string, tag = "1")]
    pub id: String,
    #[prost(string, tag = "2")]
    pub name: String,
    #[prost(string, tag = "4")]
    pub avatar_url: String,
    #[prost(string, tag = "6")]
    pub phone: String,
    #[prost(string, tag = "7")]
    pub email: String,
}
