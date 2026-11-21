import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';
import '../../ui/button.dart';
import '../../ui/load_state.dart';
import '../../ui/progress.dart';
import '../../ui/theme.dart';
import '../home/models.dart';
import 'bubble.dart';
import 'controller.dart';

/// 移动端完整页面、桌面右侧详情共用同一聊天实现。
class MessagePage extends StatefulWidget {
  const MessagePage({
    required this.client,
    required this.peer,
    required this.generation,
    required this.strings,
    this.onBack,
    this.onSent,
    super.key,
  });
  final CoreClient client;
  final Peer peer;
  final int generation;
  final Strings strings;
  final VoidCallback? onBack, onSent;
  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  late final _model = MessageController(
    widget.client,
    widget.peer,
    widget.generation,
  )..load();
  final _input = TextEditingController();
  final _focus = FocusNode();
  @override
  void dispose() {
    _model.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (await _model.send(_input.text) && mounted) {
      _input.clear();
      widget.onSent?.call();
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Tg.grouped,
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            ColoredBox(
              color: Tg.background,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    if (widget.onBack != null)
                      TgButton(
                        onPressed: widget.onBack,
                        label: widget.strings('cancel'),
                        padding: const EdgeInsets.all(16),
                        child: const TgIcon('ic_ab_back'),
                      )
                    else
                      const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.peer.title,
                        style: Tg.text(20, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _model,
                builder: (context, _) => LoadState(
                  strings: widget.strings,
                  loading: _model.loading,
                  error: _model.error,
                  emptyLabel: 'emptyMessages',
                  isEmpty: _model.messages.isEmpty,
                  onRetry: _model.load,
                  child: ListView.builder(
                    reverse: true,
                    itemCount:
                        _model.messages.length + (_model.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _model.messages.length) {
                        return TgTextButton(
                          widget.strings('older'),
                          onPressed: () => _model.load(older: true),
                        );
                      }
                      final m = _model.messages[i];
                      return MessageBubble(
                        key: ValueKey(m['msgId']),
                        data: m,
                        strings: widget.strings,
                        group: widget.peer.type == 2,
                      );
                    },
                  ),
                ),
              ),
            ),
            ColoredBox(
              color: Tg.background,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: EditableText(
                        controller: _input,
                        focusNode: _focus,
                        style: Tg.text(17),
                        cursorColor: Tg.blue,
                        backgroundCursorColor: Tg.divider,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _model,
                      builder: (context, _) => TgButton(
                        onPressed: _model.sending ? null : _send,
                        label: widget.strings('send'),
                        padding: const EdgeInsets.all(16),
                        child: _model.sending
                            ? const TgProgress()
                            : const TgIcon('msg_send', color: Tg.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
