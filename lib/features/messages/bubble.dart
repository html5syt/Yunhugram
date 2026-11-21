import 'package:flutter/widgets.dart';
import '../../l10n/strings.dart';
import '../../ui/theme.dart';

/// 基础文本消息；媒体和交互消息在后续聊天模块实现，不隐藏其存在。
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.data,
    required this.strings,
    required this.group,
    super.key,
  });
  final Map<String, dynamic> data;
  final Strings strings;
  final bool group;
  @override
  Widget build(BuildContext context) {
    final outgoing = data['direction'] == 'right';
    final supported = data['contentType'] == 1;
    final recalled = (data['recallTimestamp'] as num) > 0;
    final content = data['content'] as Map<String, dynamic>?;
    final text = recalled
        ? strings('recalled')
        : supported
        ? (content?['text'] as String? ?? '')
        : strings('messageUnsupported');
    final date = DateTime.fromMillisecondsSinceEpoch(
      (data['sendTimestampMs'] as num).toInt(),
    );
    final sender = data['sender'] as Map<String, dynamic>?;
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width.clamp(200, 520) * .75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
          decoration: BoxDecoration(
            color: outgoing ? const Color(0xffefffde) : Tg.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group && !outgoing && sender != null)
                Text(
                  sender['name'] as String,
                  style: Tg.text(
                    14,
                    color: Tg.blueText,
                    weight: FontWeight.w500,
                  ),
                ),
              Text(
                text,
                style: Tg.text(16, color: recalled ? Tg.muted : Tg.foreground),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  style: Tg.text(11, color: Tg.date),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
