//! 对话、通讯录、搜索和分享；保持服务端摘要的“未变化”语义。
use crate::{
    engine::{Engine, required},
    network::{CoreError, Result},
    protocol::{ContactResponse, ConversationResponse, ListRequest},
};
use prost::Message;
use reqwest::Method;
use serde_json::{Value, json};

impl Engine {
    pub async fn home_command(&mut self, kind: &str, args: &Value) -> Result<Value> {
        match kind {
            "getSelf" => Ok(json!(self.user)),
            "getConversations" | "getContacts" => {
                let key = if kind == "getContacts" {
                    "contacts"
                } else {
                    "chats"
                };
                let hash = if args["force"] == true {
                    String::new()
                } else {
                    self.cache.hash(key)
                };
                let body = ListRequest { md5: hash.clone() }.encode_to_vec();
                let (data, md5) = if kind == "getContacts" {
                    let response: ContactResponse = self
                        .net
                        .protobuf(
                            "v1/friend/address-book-list",
                            &self.token,
                            Method::POST,
                            body,
                        )
                        .await?;
                    (json!(response.data), response.md5)
                } else {
                    let response: ConversationResponse = self
                        .net
                        .protobuf("v1/conversation/list", &self.token, Method::POST, body)
                        .await?;
                    (json!(response.data), response.md5)
                };
                let data = self.cache.merge(key, &hash, md5, data);
                self.save_cache();
                Ok(json!({"list":data}))
            }
            "search" => {
                self.net
                    .json(
                        "v1/search/home-search",
                        &self.token,
                        json!({"word":required(args,"word")?}),
                    )
                    .await
            }
            "markRead" => {
                self.net
                    .json(
                        "v1/conversation/dismiss-notification",
                        &self.token,
                        json!({"chatId":required(args,"chatId")?}),
                    )
                    .await
            }
            "removeConversation" => {
                self.net
                    .json(
                        "v1/conversation/remove",
                        &self.token,
                        json!({"chatId":required(args,"chatId")?}),
                    )
                    .await
            }
            "createShare" => {
                let user = self
                    .user
                    .as_ref()
                    .ok_or_else(|| CoreError::new("sessionExpired", "请重新登录"))?;
                let data = self
                    .net
                    .json(
                        "v1/share/create",
                        &self.token,
                        json!({"chatId":user.id,"chatType":1,"chatName":user.name}),
                    )
                    .await?;
                let base = data["shareUrl"]
                    .as_str()
                    .ok_or_else(|| CoreError::new("protocol", "服务器没有返回分享地址"))?;
                let key = required(&data, "key")?;
                let mut url = reqwest::Url::parse(base)
                    .map_err(|_| CoreError::new("protocol", "服务器返回了无效分享地址"))?;
                url.set_path("/share");
                url.query_pairs_mut()
                    .append_pair("key", key)
                    .append_pair("ts", &data["ts"].to_string());
                Ok(json!({"url":url.as_str()}))
            }
            _ => Err(CoreError::new("request", "未知的核心命令")),
        }
    }
}
