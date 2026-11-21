import 'package:flutter/widgets.dart';
import '../../core/client.dart';
import '../../l10n/strings.dart';
import '../../ui/button.dart';
import '../../ui/field.dart';
import '../../ui/progress.dart';
import '../../ui/theme.dart';
import 'challenge.dart';
import 'slider_puzzle.dart';

/// 滑动与图形验证码共用模态流程；验证结果由真实短信接口确认。
class CaptchaPanel extends StatefulWidget {
  const CaptchaPanel({required this.client, required this.strings, super.key});
  final CoreClient client;
  final Strings strings;
  @override
  State<CaptchaPanel> createState() => _CaptchaPanelState();
}

class _CaptchaPanelState extends State<CaptchaPanel> {
  bool _image = false;
  bool _loading = false;
  String? _error;
  Challenge? _challenge;
  double _x = 0;
  final _code = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _challenge = null;
      _x = 0;
      _code.clear();
    });
    try {
      final data = await widget.client.request('getCaptcha', {
        'mode': _image ? 'image' : 'slide',
      });
      if (mounted) setState(() => _challenge = Challenge(data, _image));
    } catch (_) {
      if (mounted) setState(() => _error = widget.strings('verifyFailure'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _confirm() {
    final c = _challenge;
    if (c == null || (c.image && _code.text.trim().isEmpty)) return;
    Navigator.pop(context, {
      'id': c.id,
      if (c.image)
        'code': _code.text.trim()
      else ...{
        'captchaType': 'slide',
        'x': _x.round(),
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final c = _challenge;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s('verify'), style: Tg.text(20, weight: FontWeight.w600)),
        const SizedBox(height: 20),
        if (_loading)
          Center(
            child: Semantics(label: s('loading'), child: const TgProgress()),
          ),
        if (_error != null) Text(_error!, style: Tg.text(15, color: Tg.danger)),
        if (c != null) ...[
          if (c.image) ...[
            Image.memory(
              c.background,
              height: 100,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            TgField(
              controller: _code,
              label: s('imageCode'),
              onSubmitted: (_) => _confirm(),
            ),
          ] else
            SliderPuzzle(
              challenge: c,
              x: _x,
              onChanged: (value) => setState(() => _x = value),
              strings: s,
            ),
        ],
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            TgTextButton(
              s(_image ? 'useSlide' : 'useImage'),
              onPressed: _loading
                  ? null
                  : () {
                      _image = !_image;
                      _load();
                    },
            ),
            TgTextButton(s('refresh'), onPressed: _loading ? null : _load),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TgTextButton(s('cancel'), onPressed: () => Navigator.pop(context)),
            TgTextButton(s('confirm'), onPressed: c == null ? null : _confirm),
          ],
        ),
      ],
    );
  }
}
