//! 核心状态和命令调度；同一客户端的业务命令依次执行。
use crate::{
    auth,
    cache::Cache,
    network::{CoreError, Network, Result},
    protocol::User,
    socket::{self, Updates},
};
use serde::Deserialize;
use serde_json::{Value, json};
use tokio::task::JoinHandle;

#[derive(Deserialize)]
pub struct Configuration {
    pub device_id: String,
    pub platform: String,
    pub cache_dir: String,
}
pub struct Engine {
    pub net: Network,
    pub config: Configuration,
    pub token: String,
    pub user: Option<User>,
    pub cache: Cache,
    pub updates: Updates,
    pub socket: Option<JoinHandle<()>>,
    pub generation: u64,
}
impl Engine {
    pub fn new(config: Configuration, updates: Updates) -> Result<Self> {
        if config.device_id.is_empty() || config.cache_dir.is_empty() {
            return Err(CoreError::new("configuration", "缺少设备或保存目录设置"));
        }
        let cache = Cache::open(&config.cache_dir);
        Ok(Self {
            net: Network::new()?,
            config,
            token: String::new(),
            user: None,
            cache,
            updates,
            socket: None,
            generation: 0,
        })
    }
    pub async fn execute(&mut self, args: &Value) -> Result<Value> {
        let kind = args["@type"].as_str().unwrap_or_default();
        let result = self.dispatch(kind, args).await;
        if result.as_ref().is_err_and(|e| e.kind == "sessionExpired") {
            self.clear_session();
        }
        result
    }
    async fn dispatch(&mut self, kind: &str, args: &Value) -> Result<Value> {
        if kind == "getCaptcha" {
            return self
                .net
                .json(
                    if args["mode"] == "image" {
                        "v1/user/captcha"
                    } else {
                        "v1/captcha/get"
                    },
                    "",
                    json!({}),
                )
                .await;
        }
        if let Some((path, body)) =
            auth::request(kind, args, &self.config.device_id, &self.config.platform)
        {
            let data = self.net.json(path, "", body).await?;
            if kind == "sendCode" {
                return Ok(data);
            }
            if let Some(token) = data["token"].as_str() {
                return self.open_session(token.to_owned()).await;
            }
            if kind == "registerPhone" {
                return Ok(json!({"registered":true}));
            }
            return Err(CoreError::new("protocol", "登录响应缺少账号凭据"));
        }
        match kind {
            "restoreSession" => self.open_session(required(args, "token")?.to_owned()).await,
            "logout" => {
                self.require_session()?;
                self.net
                    .json(
                        "v1/user/logout",
                        &self.token,
                        json!({"device-id":self.config.device_id}),
                    )
                    .await?;
                self.clear_session();
                Ok(json!({}))
            }
            _ => {
                self.require_session()?;
                self.home_command(kind, args).await
            }
        }
    }
    pub fn require_session(&self) -> Result<()> {
        if self.user.is_none() {
            Err(CoreError::new("sessionExpired", "请重新登录"))
        } else {
            Ok(())
        }
    }
    pub fn clear_session(&mut self) {
        if let Some(task) = self.socket.take() {
            task.abort();
        }
        self.token.clear();
        self.user = None;
        self.generation += 1;
        self.cache.set_owner("");
        self.save_cache();
        socket::publish(
            &self.updates,
            json!({"@type":"updateAuthorization","state":"loginRequired","generation":self.generation}),
        );
    }
    pub fn save_cache(&self) {
        if self.cache.save().is_err() {
            socket::publish(
                &self.updates,
                json!({"@type":"updateWarning","kind":"storage","message":"无法保存到本地，请检查可用空间和目录权限"}),
            );
        }
    }
}
impl Drop for Engine {
    fn drop(&mut self) {
        if let Some(task) = self.socket.take() {
            task.abort();
        }
    }
}

pub fn required<'a>(args: &'a Value, key: &str) -> Result<&'a str> {
    args[key]
        .as_str()
        .filter(|s| !s.is_empty())
        .ok_or_else(|| CoreError::new("request", "操作参数不完整，请重试"))
}
