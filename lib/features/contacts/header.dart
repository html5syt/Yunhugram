import 'package:flutter/widgets.dart';
import '../../l10n/strings.dart';
import '../../ui/button.dart';
import '../../ui/theme.dart';

/// 分组按钮用箭头和操作说明表示展开状态，不单靠颜色。
class ContactsHeader extends StatelessWidget {
  const ContactsHeader({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onTap,
    required this.strings,
    this.loading = false,
    super.key,
  });
  final String title;
  final int count;
  final bool expanded, loading;
  final VoidCallback onTap;
  final Strings strings;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Tg.grouped,
    child: TgButton(
      label: '${strings(title)}, ${strings(expanded ? 'collapse' : 'expand')}',
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ExcludeSemantics(
        child: Row(
          children: [
            AnimatedRotation(
              turns: expanded ? 0.25 : 0.0,
              duration: Tg.duration,
              child: const TgIcon('msg_arrowright', size: 20, color: Tg.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings(title),
                style: Tg.text(15, color: Tg.blueText, weight: FontWeight.w500),
              ),
            ),
            if (!loading) Text('$count', style: Tg.text(14, color: Tg.muted)),
          ],
        ),
      ),
    ),
  );
}
