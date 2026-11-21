import 'package:flutter/widgets.dart';
import '../../l10n/strings.dart';
import '../../ui/list_cell.dart';
import '../../ui/load_state.dart';
import 'controller.dart';
import 'models.dart';

/// 只为当前可见对话创建行，自绘文字和计数；滚动位置由存储键保留。
class ChatsView extends StatelessWidget {
  const ChatsView({
    required this.controller,
    required this.strings,
    required this.onOpen,
    this.selected,
    this.onDelete,
    super.key,
  });
  final HomeController controller;
  final Strings strings;
  final ValueChanged<Peer> onOpen;
  final ValueChanged<Conversation>? onDelete;
  final String? selected;
  String _time(DateTime d) {
    if (d.millisecondsSinceEpoch <= 0) return '';
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      controller.conversations,
      controller.chatLoading,
      controller.chatError,
    ]),
    builder: (context, _) {
      final rows = controller.conversations.value;
      return LoadState(
        strings: strings,
        loading: controller.chatLoading.value,
        error: controller.chatError.value,
        emptyLabel: 'emptyChats',
        isEmpty: rows.isEmpty,
        onRetry: () => controller.refresh(force: true),
        child: ListView.builder(
          key: const PageStorageKey('chats'),
          itemExtent: MediaQuery.textScalerOf(context).scale(40) + 24 > 72
              ? null
              : 72,
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final c = rows[i];
            return TgListCell(
              key: ValueKey(c.peer.key),
              id: c.peer.key,
              title: c.peer.title,
              subtitle: c.preview,
              avatar: c.peer.avatar,
              time: _time(c.sentAt),
              unread: c.unread,
              muted: c.muted,
              mentioned: c.mentioned,
              selected: selected == c.peer.key,
              onTap: () => onOpen(c.peer),
              onLongPress: onDelete == null ? null : () => onDelete!(c),
            );
          },
        ),
      );
    },
  );
}
