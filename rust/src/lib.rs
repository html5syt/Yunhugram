//! YunhuLib 的 C 接口；业务请求和更新队列在后续功能提交中实现。

/// 返回接口版本，供 Dart 与原生库检查兼容性。
#[unsafe(no_mangle)]
pub extern "C" fn yh_abi_version() -> u32 {
    1
}

#[cfg(test)]
mod tests {
    #[test]
    fn abi_version_is_one() {
        assert_eq!(super::yh_abi_version(), 1);
    }
}
