import 'package:flutter/widgets.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';
import '../../ui/button.dart';
import '../../ui/field.dart';
import '../../ui/progress.dart';
import '../../ui/theme.dart';

/// 创建入口使用云湖客户端接口；不在界面暴露机器人管理凭据。
class BotPanel extends StatefulWidget {
  const BotPanel({
    required this.client,
    required this.strings,
    required this.avatar,
    super.key,
  });
  final CoreClient client;
  final Strings strings;
  final String avatar;
  @override
  State<BotPanel> createState() => _BotPanelState();
}

class _BotPanelState extends State<BotPanel> {
  final _name = TextEditingController(), _intro = TextEditingController();
  late final _avatar = TextEditingController(text: widget.avatar);
  bool _private = true, _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _intro.dispose();
    _avatar.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = widget.strings('nicknameRequired'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.client.request('createBot', {
        'name': _name.text.trim(),
        'introduction': _intro.text.trim(),
        'avatarUrl': _avatar.text.trim(),
        'private': _private,
      });
      if (mounted) Navigator.pop(context, true);
    } on ClientError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s('createBot'), style: Tg.text(20, weight: FontWeight.w600)),
        const SizedBox(height: 20),
        TgField(controller: _name, label: s('botName'), enabled: !_busy),
        TgField(controller: _intro, label: s('botIntro'), enabled: !_busy),
        // TODO(机器人管理阶段)：选择本机图片与后续管理在独立模块实现。
        TgField(controller: _avatar, label: s('botAvatar'), enabled: !_busy),
        TgButton(
          onPressed: _busy ? null : () => setState(() => _private = !_private),
          child: Row(
            children: [
              CustomPaint(size: const Size(20, 20), painter: _Check(_private)),
              const SizedBox(width: 12),
              Expanded(child: Text(s('botPrivate'), style: Tg.text(16))),
            ],
          ),
        ),
        if (_error != null) Text(_error!, style: Tg.text(15, color: Tg.danger)),
        if (_busy) const Center(child: TgProgress()),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TgTextButton(
              s('cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TgTextButton(s('create'), onPressed: _busy ? null : _create),
          ],
        ),
      ],
    );
  }
}

class _Check extends CustomPainter {
  _Check(this.value);
  final bool value;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
      Paint()..color = value ? Tg.blue : Tg.divider,
    );
    if (value) {
      canvas.drawPath(
        Path()
          ..moveTo(4, 10)
          ..lineTo(8, 14)
          ..lineTo(16, 6),
        Paint()
          ..color = Tg.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_Check old) => old.value != value;
}
