# 发布与 Android 签名

版本来自 [应用配置](../pubspec.yaml)。自动检查与调试版本工作流在 main／master 上传后执行。

正式发布支持：

- 推送 `vX.Y.Z` tag。
- 提交消息包含 `[release ver="v0.1.0", pre=false, draft=false]`。
- 手动运行“正式版本发布”，填写已经存在的 tag。

工作流检查 tag 与应用版本一致。桌面包来自相同提交。Android 只有正式签名配置完整时才生成并发布，不会用调试签名代替。

## GitHub Secrets

在仓库 Settings → Secrets and variables → Actions 中添加：

| 名称 | 内容 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | 自有 JKS 签名文件的 Base64 内容 |
| `ANDROID_KEYSTORE_PASSWORD` | 签名文件密码 |
| `ANDROID_KEY_ALIAS` | 密钥别名 |
| `ANDROID_KEY_PASSWORD` | 密钥密码 |

不要把密钥、密码或云湖登录凭据发到对话中，不要提交签名文件。配置后手动运行“正式版本发布”，tag 选择 `v0.1.0`，正式 APK 会补充到同一 Release。

缺少 Android 签名不会阻止公开源代码与桌面版本发布；发布说明会明确提示 Android 正式包待补充。

本机可使用 `flutter build apk --debug` 验证界面。调试安装包与正式安装包使用不同签名，切换时可能需要先卸载旧版本；卸载会清除该设备的本机登录与应用数据。

Windows 需要 Visual Studio C++ 桌面工具及 ATL 组件。Linux 需要 GTK 和系统安全存储服务；macOS 与 iOS 需要相应 Apple 开发工具。iOS 未签名检查产物不能直接安装到普通设备。
