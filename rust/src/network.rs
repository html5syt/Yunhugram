//! HTTP 与服务端错误处理；不记录密码或登录凭据。
use crate::protocol::{Status, StatusResponse};
use prost::Message;
use reqwest::{Client, Method};
use serde_json::{Value, json};
use std::time::Duration;

pub const API_URL: &str = "https://chat-go.jwzhd.com/";
pub const WS_URL: &str = "wss://chat-ws-go.jwzhd.com/ws";

#[derive(Debug)]
pub struct CoreError {
    pub kind: &'static str,
    pub message: String,
}
impl CoreError {
    pub fn new(kind: &'static str, message: impl Into<String>) -> Self {
        Self {
            kind,
            message: message.into(),
        }
    }
    pub fn value(&self) -> Value {
        json!({"kind":self.kind,"message":self.message})
    }
}
pub type Result<T> = std::result::Result<T, CoreError>;

/// 成功状态必须由服务端返回，缺少状态不被视为成功。
pub fn check_status(status: Option<&Status>) -> Result<()> {
    let Some(s) = status else {
        return Err(CoreError::new("protocol", "服务器响应缺少状态"));
    };
    if s.code == 1 {
        Ok(())
    } else {
        Err(CoreError::new(
            if s.code as i64 == -101 {
                "sessionExpired"
            } else {
                "api"
            },
            &s.msg,
        ))
    }
}

pub struct Network {
    client: Client,
}
impl Network {
    pub fn new() -> Result<Self> {
        let client = Client::builder()
            .timeout(Duration::from_secs(25))
            .user_agent("Yunhugram/0.1.0")
            .build()
            .map_err(|_| CoreError::new("network", "无法准备安全连接"))?;
        Ok(Self { client })
    }
    async fn bytes(
        &self,
        path: &str,
        token: &str,
        method: Method,
        body: Vec<u8>,
        content: &str,
    ) -> Result<Vec<u8>> {
        let mut request = self
            .client
            .request(method, format!("{API_URL}{path}"))
            .header("Content-Type", content);
        if !token.is_empty() {
            request = request.header("token", token);
        }
        let response = request
            .body(body)
            .send()
            .await
            .map_err(|_| CoreError::new("network", "连接失败，请检查网络后重试"))?;
        if !response.status().is_success() {
            return Err(CoreError::new(
                "network",
                format!("服务器返回 {}，请稍后重试", response.status().as_u16()),
            ));
        }
        response
            .bytes()
            .await
            .map(|b| b.to_vec())
            .map_err(|_| CoreError::new("network", "响应读取失败，请重试"))
    }
    pub async fn json(&self, path: &str, token: &str, body: Value) -> Result<Value> {
        let bytes = self
            .bytes(
                path,
                token,
                Method::POST,
                body.to_string().into_bytes(),
                "application/json",
            )
            .await?;
        let value: Value = serde_json::from_slice(&bytes)
            .map_err(|_| CoreError::new("protocol", "服务器没有返回有效数据"))?;
        check_json(&value)?;
        Ok(value.get("data").cloned().unwrap_or_else(|| json!({})))
    }
    pub async fn protobuf<T: Message + Default>(
        &self,
        path: &str,
        token: &str,
        method: Method,
        body: Vec<u8>,
    ) -> Result<T> {
        let bytes = self
            .bytes(path, token, method, body, "application/x-protobuf")
            .await?;
        // 未登录等错误有时以 JSON 返回，即使此接口正常使用 Protobuf。
        if let Ok(value) = serde_json::from_slice::<Value>(&bytes) {
            check_json(&value)?;
            return Err(CoreError::new("protocol", "服务器返回了不同的数据格式"));
        }
        let status = StatusResponse::decode(bytes.as_slice())
            .map_err(|_| CoreError::new("protocol", "无法读取服务器状态"))?;
        check_status(status.status.as_ref())?;
        T::decode(bytes.as_slice()).map_err(|_| CoreError::new("protocol", "服务器数据格式不匹配"))
    }
}
fn check_json(value: &Value) -> Result<()> {
    match value["code"].as_i64() {
        Some(1) => Ok(()),
        code => Err(CoreError::new(
            if code == Some(-101) {
                "sessionExpired"
            } else {
                "api"
            },
            value["msg"].as_str().unwrap_or("服务器没有返回状态说明"),
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn no_status_is_never_success() {
        assert!(check_status(None).is_err());
    }
    #[test]
    fn session_expiry_is_distinct_from_network_failure() {
        assert_eq!(
            check_json(&json!({"code":-101,"msg":"未登录"}))
                .unwrap_err()
                .kind,
            "sessionExpired"
        );
    }
}
