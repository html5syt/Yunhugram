import 'package:flutter/widgets.dart';
import 'zh.dart';
import 'en.dart';

/// 界面文本集中维护，默认中文；服务端返回的用户内容不擅自翻译。
class Strings {
  const Strings(this.locale);
  final Locale locale;
  String call(String key) =>
      (locale.languageCode == 'en' ? en : zh)[key] ?? zh[key] ?? key;
  static const zh = zhStrings;
  static const en = enStrings;
}
