import 'package:flutter/widgets.dart';
import '../l10n/strings.dart';
import 'button.dart';
import 'progress.dart';
import 'theme.dart';

/// 有明确原因与重试动作的列表状态；不会用空列表掩盖请求失败。
class LoadState extends StatelessWidget {
  const LoadState({
    required this.strings,
    required this.loading,
    required this.error,
    required this.emptyLabel,
    required this.child,
    required this.isEmpty,
    required this.onRetry,
    super.key,
  });
  final Strings strings;
  final bool loading, isEmpty;
  final String? error;
  final String emptyLabel;
  final Widget child;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      if (loading) {
        return Center(
          child: Semantics(
            label: strings('loading'),
            child: const TgProgress(),
          ),
        );
      }
      if (error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!, style: Tg.text(15, color: Tg.danger)),
                const SizedBox(height: 12),
                TgTextButton(strings('retry'), onPressed: onRetry),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Text(strings(emptyLabel), style: Tg.text(16, color: Tg.muted)),
      );
    }
    return Column(
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text('! ', style: Tg.text(15, color: Tg.danger)),
                Expanded(
                  child: Text(error!, style: Tg.text(14, color: Tg.danger)),
                ),
                TgTextButton(strings('retry'), onPressed: onRetry),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
