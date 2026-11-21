import 'package:flutter/widgets.dart';
import '../l10n/strings.dart';
import 'button.dart';
import 'theme.dart';

/// 自定义 Telegram 风格模态面板，支持键盘关闭和屏幕阅读器。
Future<T?> showTgPanel<T>(
  BuildContext context,
  WidgetBuilder builder, {
  required String label,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: label,
  barrierColor: const Color(0x66000000),
  transitionDuration: Tg.duration,
  pageBuilder: (context, animation, secondary) => SafeArea(
    minimum: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width.clamp(32, 400) - 32,
          maxHeight:
              (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom -
                      MediaQuery.paddingOf(context).vertical -
                      32)
                  .clamp(64, double.infinity)
                  .toDouble(),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Tg.background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 24),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(child: builder(context)),
          ),
        ),
      ),
    ),
  ),
  transitionBuilder: (context, animation, secondary, child) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween<double>(begin: .95, end: 1).animate(animation),
      child: child,
    ),
  ),
);

Future<bool> confirmTg(
  BuildContext context,
  Strings s,
  String title,
  String message, {
  String action = 'confirm',
}) async =>
    await showTgPanel<bool>(
      context,
      (panel) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Tg.text(20, weight: FontWeight.w600)),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(message, style: Tg.text(16)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TgTextButton(
                s('cancel'),
                onPressed: () => Navigator.pop(panel, false),
              ),
              TgTextButton(
                s(action),
                onPressed: () => Navigator.pop(panel, true),
              ),
            ],
          ),
        ],
      ),
      label: title,
    ) ??
    false;

Future<void> noticeTg(BuildContext context, Strings s, String message) =>
    showTgPanel<void>(
      context,
      (panel) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Tg.text(16)),
          const SizedBox(height: 16),
          TgTextButton(s('confirm'), onPressed: () => Navigator.pop(panel)),
        ],
      ),
      label: message,
    );
