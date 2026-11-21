import 'package:flutter/widgets.dart';

/// 启动入口；使用基础 Widgets，不采用 Material 或 Cupertino 组件库。
void main() {
  runApp(
    const WidgetsApp(
      color: Color(0xff527da3),
      debugShowCheckedModeBanner: false,
      builder: _build,
    ),
  );
}

Widget _build(BuildContext context, Widget? child) => const ColoredBox(
  color: Color(0xffffffff),
  child: Center(child: Text('Yunhugram')),
);
