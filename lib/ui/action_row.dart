import 'package:flutter/widgets.dart';
import 'button.dart';
import 'theme.dart';

/// 设置与联系人入口共用的 Telegram 操作行。
class TgActionRow extends StatelessWidget {
  const TgActionRow({
    required this.title,
    required this.onTap,
    this.icon,
    this.trailing,
    super.key,
  });
  final String title;
  final VoidCallback? onTap;
  final String? icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => TgButton(
    onPressed: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        if (icon != null) ...[
          TgIcon(icon!, color: Tg.muted),
          const SizedBox(width: 24),
        ],
        Expanded(child: Text(title, style: Tg.text(16))),
        ?trailing,
      ],
    ),
  );
}
