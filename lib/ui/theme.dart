import 'package:flutter/widgets.dart';

/// Telegram Android ThemeColors 与 DialogCell/UserCell 的基础常量。
abstract final class Tg {
  static const background = Color(0xffffffff);
  static const foreground = Color(0xff1a1d21);
  static const blue = Color(0xff229af0);
  static const blueText = Color(0xff298acf);
  static const muted = Color(0xff75787a);
  static const date = Color(0xff848688);
  static const divider = Color(0xffd9d9d9);
  static const grouped = Color(0xfff0f0f0);
  static const danger = Color(0xffcf3030);
  static const barHeight = 56.0;
  static const dialogHeight = 72.0;
  static const contactHeight = 64.0;
  static const avatarSize = 54.0;
  static const duration = Duration(milliseconds: 180);
  static TextStyle text(
    double size, {
    Color color = foreground,
    FontWeight weight = FontWeight.normal,
  }) => TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    decoration: TextDecoration.none,
  );
}

/// 直接使用 Telegram 原始素材，不以 Material 或 emoji 图标代替。
class TgIcon extends StatelessWidget {
  const TgIcon(
    this.name, {
    this.size = 24,
    this.color = Tg.foreground,
    super.key,
  });
  final String name;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/telegram/$name.webp',
    width: size,
    height: size,
    color: color,
    colorBlendMode: BlendMode.srcIn,
    excludeFromSemantics: true,
  );
}
