# 开发与验证

## 固定工具版本

- Flutter 3.44.1，Dart 3.12.1。
- Rust 1.100.0；Android NDK 28.2.13676358。
- Windows 使用 Visual Studio 的 C++ 桌面开发工具。
- Android、Windows、Linux、macOS、iOS 均保留 Flutter 平台工程；本机直接验证 Android 与 Windows，Apple 平台需 macOS。

```sh
flutter pub get --enforce-lockfile
cargo test --manifest-path rust/Cargo.toml
flutter test
flutter run -d windows
```

Rust 通过 Dart 原生资源构建钩子生成并随应用打包，不要求用户另行安装动态库。Rust 标准库目标在工具链文件中明确列出，以满足构建钩子的校验；首次使用会下载这些目标。钩子依赖固定为兼容 Flutter 3.44.1 的 hooks 2.0.2 与 native_toolchain_rust 1.0.4+0，避免新版依赖要求更高的 Flutter 内置 meta 版本。

## 架构

Flutter 只负责界面、系统分享与安全凭据保存；Rust 负责 HTTP、Protobuf、WebSocket、业务状态、缓存。Dart FFI 采用类似 TDLib 的异步请求／结果／更新队列，不在界面线程等待网络。具体命令随功能实现扩充，不直接复用 Telegram 网络协议。

## 文本编码

所有手写文本使用 UTF-8。PowerShell 执行读写前设置 `[Console]::OutputEncoding` 与 `$OutputEncoding` 为 UTF-8，读取显式指定 `-Encoding UTF8`，写入使用无 BOM 的 UTF-8；不要在不同 shell 之间拼接文件删除／移动命令。

本机 Rust 安装在非默认目录。构建钩子的环境过滤会令 rustup 使用用户默认目录；本次搭建以明确版本目录的链接复用已有 1.100.0 工具链，未更换全局默认工具链。中断生成的不完整目录已改名保留，没有执行文件删除。

## 工作进度

1. 工具检查已完成，平台工程已生成。
2. Rust 接口版本单元测试与 Dart FFI 原生资源载入测试已通过。
3. 登录、注册、主页、联系人尚未实现。
4. GitHub 工作流与 v0.1.0 尚未发布。

功能完成后分别提交。签名密钥不进入代码仓库，也不使用调试密钥冒充正式签名。
