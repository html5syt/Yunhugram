import 'package:flutter/widgets.dart';
import 'theme.dart';

/// 使用 Flutter 图像缓存与目标像素尺寸，下载失败时绘制名字首字。
class TgAvatar extends StatelessWidget {
  const TgAvatar({
    required this.id,
    required this.name,
    this.url = '',
    this.size = 54,
    super.key,
  });
  final String id, name, url;
  final double size;
  static const _colors = [
    Color(0xffff845e),
    Color(0xfffebb5b),
    Color(0xffb694f9),
    Color(0xff9ad164),
    Color(0xff5bcbe3),
    Color(0xff5caffa),
    Color(0xffff8aac),
  ];
  Widget _fallback() => ColoredBox(
    color: _colors[id.codeUnits.fold<int>(0, (a, b) => a + b) % _colors.length],
    child: Center(
      child: Text(
        name.isEmpty ? '' : String.fromCharCode(name.runes.first).toUpperCase(),
        style: Tg.text(
          size * .4,
          color: Tg.background,
          weight: FontWeight.w500,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: url.isEmpty
              ? _fallback()
              : Image.network(
                  url.startsWith('https://') || url.startsWith('http://')
                      ? url
                      : 'https://chat-img.jwznb.com/$url',
                  headers: const {'Referer': 'http://myapp.jwznb.com'},
                  fit: BoxFit.cover,
                  cacheWidth: pixels,
                  cacheHeight: pixels,
                  errorBuilder: (_, error, stack) => _fallback(),
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : _fallback(),
                ),
        ),
      ),
    );
  }
}
