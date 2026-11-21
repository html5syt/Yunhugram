import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'app/controller.dart';

/// 系统插件与 Dart FFI 初始化后，按真实登录状态选择页面。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xffffffff),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xffffffff),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final controller = AppController();
  runApp(YunhugramApp(controller: controller));
  unawaited(controller.initialize());
}
