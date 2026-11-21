//! 登录状态创建与当前账号资料读取。
use crate::{
    engine::Engine,
    network::{CoreError, Result},
    protocol::UserResponse,
    socket,
};
use reqwest::Method;
use serde_json::{Value, json};

impl Engine {
    pub async fn open_session(&mut self, token: String) -> Result<Value> {
        let response: UserResponse = self
            .net
            .protobuf("v1/user/info", &token, Method::GET, vec![])
            .await?;
        let user = response
            .data
            .filter(|u| !u.id.is_empty())
            .ok_or_else(|| CoreError::new("protocol", "账号资料响应不完整"))?;
        if let Some(task) = self.socket.take() {
            task.abort();
        }
        self.generation += 1;
        self.token = token;
        self.user = Some(user.clone());
        self.cache.set_owner(&user.id);
        self.save_cache();
        self.socket = Some(tokio::spawn(socket::run(
            self.updates.clone(),
            user.id.clone(),
            self.token.clone(),
            self.config.device_id.clone(),
            self.config.platform.clone(),
            self.generation,
        )));
        Ok(json!({"user":user,"token":self.token,"generation":self.generation}))
    }
}
