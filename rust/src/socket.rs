//! 云湖 WebSocket 登录、检测与重连；更新通过共享队列返回 Dart。
use crate::{network::WS_URL, protocol::WsWrapper};
use futures_util::{SinkExt, StreamExt};
use prost::Message;
use serde_json::{Value, json};
use std::{
    collections::VecDeque,
    sync::{Arc, Mutex},
    time::Duration,
};
use tokio_tungstenite::{connect_async, tungstenite::Message as Frame};

pub type Updates = Arc<Mutex<VecDeque<Value>>>;
/// 只在互斥锁内移动结果，不执行网络或磁盘操作。
pub fn publish(queue: &Updates, value: Value) {
    if let Ok(mut q) = queue.lock() {
        q.push_back(value);
    }
}
pub async fn run(
    queue: Updates,
    user_id: String,
    token: String,
    device: String,
    platform: String,
    generation: u64,
) {
    let mut delay = 1u64;
    loop {
        publish(
            &queue,
            json!({"@type":"updateConnection","state":"connecting","generation":generation}),
        );
        if let Ok(Ok((mut socket, _))) =
            tokio::time::timeout(Duration::from_secs(20), connect_async(WS_URL)).await
        {
            let auth = json!({"seq":uuid::Uuid::new_v4().simple().to_string(),"cmd":"login","data":{"userId":user_id,"token":token,"deviceId":device,"platform":platform}});
            if socket
                .send(Frame::Text(auth.to_string().into()))
                .await
                .is_ok()
            {
                let mut interval = tokio::time::interval(Duration::from_secs(25));
                let mut last = tokio::time::Instant::now();
                let mut online = false;
                loop {
                    tokio::select! {
                        _=interval.tick()=> {
                            if last.elapsed()>Duration::from_secs(70) {break;}
                            let frame=json!({"seq":uuid::Uuid::new_v4().simple().to_string(),"cmd":"heartbeat","data":{}});
                            if socket.send(Frame::Text(frame.to_string().into())).await.is_err() {break;}
                        }
                        message=socket.next()=> {
                            let command=match message {
                                Some(Ok(Frame::Binary(bytes)))=>WsWrapper::decode(bytes.as_ref()).ok().and_then(|w|w.info).map(|i|i.cmd),
                                Some(Ok(Frame::Text(text)))=> {
                                    if text.contains("数据不合法") {break;}
                                    serde_json::from_str::<Value>(&text).ok().and_then(|v|v["cmd"].as_str().map(str::to_owned))
                                }
                                Some(Ok(Frame::Ping(bytes)))=> {if socket.send(Frame::Pong(bytes)).await.is_err(){break;}continue;}
                                Some(Ok(Frame::Pong(_)))=>continue,
                                Some(Ok(Frame::Close(_)))|None|Some(Err(_))=>break,
                                _=>continue,
                            };
                            if let Some(cmd)=command {
                                last=tokio::time::Instant::now();
                                // 只有收到已登录账号可获得的确认／推送，才显示已连接。
                                if matches!(cmd.as_str(),"heartbeat_ack"|"push_message"|"invite_apply"|"edit_message") {
                                    if !online {online=true;delay=1;publish(&queue,json!({"@type":"updateConnection","state":"online","generation":generation}));}
                                    if cmd!="heartbeat_ack" {publish(&queue,json!({"@type":"updateRefresh","generation":generation,"reason":cmd}));}
                                }
                            }
                        }
                    }
                }
            }
        }
        publish(
            &queue,
            json!({"@type":"updateConnection","state":"waiting","generation":generation}),
        );
        // 断开后让 HTTP 接口核验会话，不把“数据不合法”直接当作失效凭据。
        publish(
            &queue,
            json!({"@type":"updateRefresh","generation":generation,"reason":"connectionClosed"}),
        );
        tokio::time::sleep(Duration::from_secs(delay)).await;
        delay = (delay * 2).min(30);
    }
}
