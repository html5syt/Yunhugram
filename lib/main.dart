import 'dart:async';
import 'package:flutter/widgets.dart';
import 'app/app.dart';
import 'app/controller.dart';

/// 系统插件与 Dart FFI 初始化后，按真实登录状态选择页面。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  runApp(YunhugramApp(controller: controller));
  unawaited(controller.initialize());
}
