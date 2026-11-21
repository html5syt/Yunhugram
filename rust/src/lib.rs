//! YunhuLib：独立于 Flutter 的云湖客户端核心库。
mod auth;
mod cache;
mod engine;
mod ffi;
mod home;
mod network;
mod protocol;
mod session;
mod socket;

pub use ffi::*;

/// 返回 Dart／原生库接口版本。
#[unsafe(no_mangle)]
pub extern "C" fn yh_abi_version() -> u32 {
    1
}
