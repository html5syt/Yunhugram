# 参考依据

## Telegram

界面参考 [DrKLO/Telegram](https://github.com/DrKLO/Telegram) 的 ActionBar、Theme、LoginActivity、UserCell 和 DialogCell。原代码按 GPL-2.0-or-later 授权；本项目采用相同许可证。TDLib 的异步命令和更新机制用于架构参考，不使用 Telegram 服务端协议。参考副本保存在已忽略的 `.references/`。

## 云湖

接口参考 [yhchatAPI](https://github.com/yh-Tpdev/yhchatAPI)，使用客户端 v1 路由，不使用机器人服务端接口。协议字段以文档中的 full.proto 为依据。文档采用 CC-BY-SA 4.0；接口事实和字段定义的依据在这里单独注明，不复制整个文档。

应用图标来自用户提供的云湖 Android 1.6.34 资源 `images/appIcon/icon_original.png`。图标及云湖名称属于原权利人，不因本项目的代码许可证改变其权利；本项目不是云湖官方客户端。

## 注册请求的静态证据

样本 libapp.so SHA-256：`02f70b6d1c115745b4c057967651df91e111d9f48ff1bad720f01a840fdd403b`。IDA 样本与提供的 Android 资源原生库一致。Dart 3.14.0、arm64、product、compressed_pointers，函数名有混淆。

- 对象池 `pp+0x4e370`：`v1/user/verification-register`。
- ARM64 引用指令 `0x16ee6dc`，所属函数 `0x16ee598`，调用发送函数 `0x8bfd98`。
- `0x16ee5f8` 到 `0x16ee660` 构建的键值：`mobile`、`captcha`、`deviceId`、`platform`、`nickname`、`inviteCode`。
- 平台字段原样本是 `android`，设备字段来自平台设备标识。客户端实现会按运行平台使用稳定随机设备标识。

以上仅为静态分析，尚未使用账号完成注册／登录验证。不将地址发现等同于后端实时有效性，不猜测不存在的邮箱注册接口。

## CI

优先参考 [HyDownloader](https://github.com/html5syt/HyDownloader) 的 Release 工作流：固定 Flutter、按 tag／提交元数据发布、多平台产物、GitHub Secrets 中的 Android 签名配置。

## 本次 UI 依据

使用当前 Telegram master 的 ThemeColors 白色顶部栏，主色 `0xff229af0`、文字 `0xff1a1d21`、消息摘要 `0xff75787a`、分隔线 `0xffd9d9d9`。DialogCell 的名称／消息字体采用 17／16，UserCell 采用 16／15。图标直接使用 DrKLO/Telegram 中的 xxhdpi WebP 资源，不使用 Material 或 Cupertino 图标库。

真实滑动验证码接口已验证返回 code=1，背景尺寸为 300×220；拼图尺寸由接口动态返回，不硬编码。
