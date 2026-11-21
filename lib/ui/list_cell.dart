import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'avatar.dart';
import 'cell_painter.dart';
import 'theme.dart';

/// 固定行高、懒加载列表和自绘内容，避免由大量文字控件拼接一行。
class TgListCell extends StatelessWidget {
  const TgListCell({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.avatar = '',
    this.time = '',
    this.unread = 0,
    this.selected = false,
    this.muted = false,
    this.mentioned = false,
    this.contact = false,
    this.onLongPress,
    super.key,
  });
  final String id, title, subtitle, avatar, time;
  final int unread;
  final bool selected, muted, mentioned, contact;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    final height = math.max(
      contact ? Tg.contactHeight : Tg.dialogHeight,
      scale.scale(40) + 24,
    );
    return Semantics(
      button: true,
      label: '$title, $subtitle${unread > 0 ? ', $unread' : ''}',
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: RepaintBoundary(
          child: SizedBox(
            height: height,
            child: ColoredBox(
              color: selected ? Tg.blue.withValues(alpha: .1) : Tg.background,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  TgAvatar(
                    id: id,
                    name: title,
                    url: avatar,
                    size: contact ? 48 : 54,
                  ),
                  SizedBox(width: contact ? 14 : 8),
                  Expanded(
                    child: CustomPaint(
                      painter: CellPainter(
                        title: title,
                        subtitle: subtitle,
                        time: time,
                        unread: unread,
                        scale: scale,
                        selected: false,
                        muted: muted,
                        mentioned: mentioned,
                        contact: contact,
                      ),
                      child: SizedBox(height: height),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
