package com.html5syt.yunhugram

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** 仅负责系统分享，不处理账号凭据或聊天业务。 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yunhugram/sharing")
            .setMethodCallHandler { call, result ->
                val target = when (call.argument<String>("target")) {
                    "wechat" -> "com.tencent.mm"
                    "qq" -> "com.tencent.mobileqq"
                    else -> null
                }
                if (target == null) {
                    result.error("target", "未知分享对象", null)
                    return@setMethodCallHandler
                }
                val launch = packageManager.getLaunchIntentForPackage(target)
                if (launch == null) {
                    result.error("missing", "未安装目标应用", null)
                    return@setMethodCallHandler
                }
                try {
                    when (call.method) {
                        "shareText" -> {
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                setPackage(target)
                                putExtra(Intent.EXTRA_TEXT, call.argument<String>("text"))
                            }
                            if (intent.resolveActivity(packageManager) != null) {
                                startActivity(intent)
                                result.success("opened")
                            } else {
                                // 部分版本不支持文本分享，由 Dart 先复制链接再打开目标应用。
                                result.success("copy")
                            }
                        }
                        "openTarget" -> { startActivity(launch); result.success(null) }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("share", "无法打开分享", null)
                }
            }
    }
}
