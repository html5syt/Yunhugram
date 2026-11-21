import 'package:flutter/widgets.dart';
import 'theme.dart';

/// 名称、摘要、时间、计数与分隔线合并绘制，并缓存同尺寸的文字布局。
class CellPainter extends CustomPainter {
  CellPainter({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.scale,
    this.selected = false,
    this.muted = false,
    this.mentioned = false,
    this.contact = false,
  });
  final String title, subtitle, time;
  final int unread;
  final TextScaler scale;
  final bool selected, muted, mentioned, contact;
  TextPainter? _title, _subtitle, _date, _count;
  double? _width;
  TextPainter _text(
    String text,
    double size,
    Color color,
    double width, {
    FontWeight weight = FontWeight.normal,
  }) => TextPainter(
    text: TextSpan(
      text: text,
      style: Tg.text(size, color: color, weight: weight),
    ),
    textDirection: TextDirection.ltr,
    textScaler: scale,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: width.clamp(0, double.infinity));
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    if (selected) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Tg.blue.withValues(alpha: .1),
      );
    }
    if (_width != size.width) {
      _date = _text(time, 13, Tg.date, size.width);
      _title = _text(
        title,
        contact ? 16 : 17,
        Tg.foreground,
        size.width - 16 - _date!.width - 12,
        weight: FontWeight.w500,
      );
      final counter = '${mentioned ? '@ ' : ''}${unread > 0 ? unread : ''}'
          .trim();
      _count = _text(counter, 12, Tg.background, 100);
      _subtitle = _text(
        subtitle,
        contact ? 15 : 16,
        Tg.muted,
        size.width - 20 - ((unread > 0 || mentioned) ? _count!.width + 24 : 0),
      );
      _width = size.width;
    }
    final center = size.height / 2;
    _title!.paint(canvas, Offset(0, center - 25));
    _subtitle!.paint(canvas, Offset(0, center + 1));
    _date!.paint(canvas, Offset(size.width - _date!.width - 12, center - 22));
    if (unread > 0 || mentioned) {
      final width = (_count!.width + 12)
          .clamp(22.0, double.infinity)
          .toDouble();
      final rect = Rect.fromLTWH(
        size.width - width - 12,
        center + 4,
        width,
        22,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(11)),
        Paint()..color = muted ? Tg.date : Tg.blue,
      );
      _count!.paint(
        canvas,
        Offset(
          rect.center.dx - _count!.width / 2,
          rect.center.dy - _count!.height / 2,
        ),
      );
    }
    canvas.drawLine(
      Offset(0, size.height - .5),
      Offset(size.width, size.height - .5),
      Paint()
        ..color = Tg.divider
        ..strokeWidth = .5,
    );
  }

  @override
  bool shouldRepaint(CellPainter old) =>
      old.title != title ||
      old.subtitle != subtitle ||
      old.time != time ||
      old.unread != unread ||
      old.selected != selected ||
      old.muted != muted ||
      old.mentioned != mentioned ||
      old.contact != contact ||
      old.scale != scale;
}
