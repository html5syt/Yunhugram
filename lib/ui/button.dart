import 'package:flutter/widgets.dart';
import 'theme.dart';

/// 统一键盘、触摸和辅助功能行为的自定义按钮。
class TgButton extends StatefulWidget {
  const TgButton({
    required this.child,
    this.onPressed,
    this.label,
    this.filled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    super.key,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final bool filled;
  final EdgeInsets padding;
  @override
  State<TgButton> createState() => _TgButtonState();
}

class _TgButtonState extends State<TgButton> {
  bool _pressed = false;
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: Tg.duration,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.filled
                  ? Tg.blue.withValues(
                      alpha: enabled ? (_pressed ? .8 : 1) : .4,
                    )
                  : (_pressed || _focused
                        ? Tg.blue.withValues(alpha: .10)
                        : null),
              borderRadius: BorderRadius.circular(widget.filled ? 8 : 4),
              border: _focused ? Border.all(color: Tg.blue) : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class TgTextButton extends StatelessWidget {
  const TgTextButton(
    this.text, {
    this.onPressed,
    this.filled = false,
    super.key,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool filled;
  @override
  Widget build(BuildContext context) => TgButton(
    onPressed: onPressed,
    filled: filled,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Tg.text(
        15,
        color: filled ? Tg.background : Tg.blueText,
        weight: FontWeight.w600,
      ),
    ),
  );
}
