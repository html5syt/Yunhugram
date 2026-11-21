import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'theme.dart';

/// Telegram 风格的标签与底线输入，不依赖 Material TextField。
class TgField extends StatefulWidget {
  const TgField({
    required this.controller,
    required this.label,
    this.password = false,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
    this.autofillHints,
    this.enabled = true,
    super.key,
  });
  final TextEditingController controller;
  final String label;
  final bool password;
  final TextInputType keyboardType;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  @override
  State<TgField> createState() => _TgFieldState();
}

class _TgFieldState extends State<TgField> {
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  void _changed() {
    setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Tg.text(13, color: _focus.hasFocus ? Tg.blueText : Tg.muted),
        ),
        const SizedBox(height: 6),
        Semantics(
          textField: true,
          label: widget.label,
          child: EditableText(
            controller: widget.controller,
            focusNode: _focus,
            readOnly: !widget.enabled,
            obscureText: widget.password,
            keyboardType: widget.keyboardType,
            textInputAction: widget.onSubmitted == null
                ? TextInputAction.next
                : TextInputAction.done,
            style: Tg.text(17),
            cursorColor: Tg.blue,
            backgroundCursorColor: Tg.divider,
            selectionColor: Tg.blue.withValues(alpha: .2),
            autocorrect: !widget.password,
            enableSuggestions: !widget.password,
            autofillHints: widget.autofillHints,
            onSubmitted: widget.onSubmitted,
            minLines: 1,
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: Tg.duration,
          height: _focus.hasFocus ? 2 : 1,
          color: _focus.hasFocus ? Tg.blue : Tg.divider,
        ),
      ],
    ),
  );
}
