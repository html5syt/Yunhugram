import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'action_row.dart';
import 'theme.dart';

class TgMenuItem {
  const TgMenuItem(this.key, this.title, this.icon);
  final String key, title, icon;
}

/// 更多菜单靠近触发按钮出现，不替换为居中说明对话框。
Future<String?> showTgMenu(
  BuildContext anchorContext,
  List<TgMenuItem> items, {
  required String label,
}) {
  final box = anchorContext.findRenderObject()! as RenderBox;
  final anchor = box.localToGlobal(Offset(box.size.width, box.size.height));
  return showGeneralDialog<String>(
    context: anchorContext,
    barrierDismissible: true,
    barrierLabel: label,
    barrierColor: const Color(0x00000000),
    transitionDuration: Tg.duration,
    pageBuilder: (context, animation, secondary) {
      final size = MediaQuery.sizeOf(context);
      final left = (anchor.dx - 240)
          .clamp(8, math.max(8, size.width - 248))
          .toDouble();
      final top = math
          .min(anchor.dy + 4, size.height - items.length * 52 - 24)
          .clamp(8, math.max(8, size.height - 24))
          .toDouble();
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: 240,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Tg.background,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 16),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in items)
                      TgActionRow(
                        title: item.title,
                        icon: item.icon,
                        onTap: () => Navigator.pop(context, item.key),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, secondary, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
