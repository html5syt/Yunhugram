//! WebSocket 外层与 Any 数据。
use prost::Message;
#[derive(Clone, PartialEq, Message)]
pub struct WsInfo {
    #[prost(string, tag = "1")]
    pub seq: String,
    #[prost(string, tag = "2")]
    pub cmd: String,
}
#[derive(Clone, PartialEq, Message)]
pub struct AnyData {
    #[prost(string, tag = "1")]
    pub type_url: String,
    #[prost(bytes = "vec", tag = "2")]
    pub value: Vec<u8>,
}
#[derive(Clone, PartialEq, Message)]
pub struct WsWrapper {
    #[prost(message, optional, tag = "1")]
    pub info: Option<WsInfo>,
    #[prost(message, optional, tag = "2")]
    pub data: Option<AnyData>,
}
