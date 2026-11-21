//! C ABI 的所有权边界。Dart 发送后即可释放入参；结果必须调用 yh_free。
use crate::{
    engine::{Configuration, Engine},
    socket::{Updates, publish},
};
use serde_json::{Value, json};
use std::{
    collections::VecDeque,
    ffi::{CStr, CString, c_char},
    sync::{Arc, Mutex},
};
use tokio::{runtime::Runtime, sync::mpsc};

pub struct Client {
    runtime: Option<Runtime>,
    sender: mpsc::Sender<Value>,
    queue: Updates,
}

/// 创建独立客户端，不使用进程级全局网络状态。
/// # Safety
/// config 必须指向有效且以 NUL 结束的 UTF-8 字符串。
#[unsafe(no_mangle)]
pub unsafe extern "C" fn yh_create(config: *const c_char) -> *mut Client {
    if config.is_null() {
        return std::ptr::null_mut();
    }
    let Ok(config) =
        serde_json::from_slice::<Configuration>(unsafe { CStr::from_ptr(config) }.to_bytes())
    else {
        return std::ptr::null_mut();
    };
    let Ok(runtime) = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(2)
        .enable_all()
        .build()
    else {
        return std::ptr::null_mut();
    };
    let queue = Arc::new(Mutex::new(VecDeque::new()));
    let Ok(mut engine) = Engine::new(config, queue.clone()) else {
        return std::ptr::null_mut();
    };
    let (sender, mut receiver) = mpsc::channel::<Value>(64);
    let updates = queue.clone();
    runtime.spawn(async move {
        while let Some(command) = receiver.recv().await {
            let extra = command.get("@extra").cloned().unwrap_or(Value::Null);
            let result = match engine.execute(&command).await {
                Ok(data) => json!({"@type":"response","@extra":extra,"data":data}),
                Err(error) => json!({"@type":"error","@extra":extra,"error":error.value()}),
            };
            publish(&updates, result);
        }
    });
    Box::into_raw(Box::new(Client {
        runtime: Some(runtime),
        sender,
        queue,
    }))
}

/// 非阻塞地提交请求；返回 0 表示已接受，负数表示参数错误或队列已满。
/// # Safety
/// client 必须是仍有效的 yh_create 结果；command 是有效 NUL 结束 UTF-8 字符串。
#[unsafe(no_mangle)]
pub unsafe extern "C" fn yh_send(client: *mut Client, command: *const c_char) -> i32 {
    if client.is_null() || command.is_null() {
        return -1;
    }
    let Ok(value) = serde_json::from_slice::<Value>(unsafe { CStr::from_ptr(command) }.to_bytes())
    else {
        return -1;
    };
    let client = unsafe { &*client };
    if client.sender.try_send(value).is_ok() {
        0
    } else {
        -2
    }
}

/// 立即取出一项结果；无结果返回空指针，不等待网络。
/// # Safety
/// client 必须仍有效；非空返回值由调用方恰好释放一次。
#[unsafe(no_mangle)]
pub unsafe extern "C" fn yh_receive(client: *mut Client) -> *mut c_char {
    if client.is_null() {
        return std::ptr::null_mut();
    }
    let client = unsafe { &*client };
    client
        .queue
        .lock()
        .ok()
        .and_then(|mut q| q.pop_front())
        .and_then(|v| CString::new(v.to_string()).ok())
        .map_or(std::ptr::null_mut(), CString::into_raw)
}

/// 释放 yh_receive 返回的字符串。
/// # Safety
/// value 只能是本库返回且尚未释放的指针。
#[unsafe(no_mangle)]
pub unsafe extern "C" fn yh_free(value: *mut c_char) {
    if !value.is_null() {
        drop(unsafe { CString::from_raw(value) });
    }
}

/// 关闭客户端，不在界面线程等待网络任务结束。
/// # Safety
/// client 只能关闭一次；关闭后不得再次发送或读取。
#[unsafe(no_mangle)]
pub unsafe extern "C" fn yh_destroy(client: *mut Client) {
    if !client.is_null() {
        let mut client = unsafe { Box::from_raw(client) };
        if let Some(runtime) = client.runtime.take() {
            runtime.shutdown_background();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn invalid_json_is_rejected_without_unwinding_across_ffi() {
        let config = CString::new("bad-json").unwrap();
        assert!(unsafe { yh_create(config.as_ptr()) }.is_null());
        assert_eq!(
            unsafe { yh_send(std::ptr::null_mut(), std::ptr::null()) },
            -1
        );
    }
}
