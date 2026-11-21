import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../ui/theme.dart';

/// 布局常量取自 Telegram Desktop window.style 和 core_settings.h。
class HomeAdaptive extends StatefulWidget {
  const HomeAdaptive({
    required this.left,
    required this.details,
    required this.placeholder,
    required this.selected,
    required this.searching,
    required this.onBack,
    super.key,
  });
  final Widget left, placeholder;
  final Widget Function(bool back) details;
  final bool selected, searching;
  final VoidCallback onBack;
  @override
  State<HomeAdaptive> createState() => _HomeAdaptiveState();
}

class _HomeAdaptiveState extends State<HomeAdaptive> {
  static const _leftMinimum = 260.0, _mainMinimum = 380.0;
  double _ratio = 5 / 14;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final wide = width >= _leftMinimum + _mainMinimum;
          final left = wide
              ? math
                    .max(_leftMinimum, width * _ratio)
                    .clamp(_leftMinimum, width - _mainMinimum)
                    .toDouble()
              : width;
          return PopScope(
            canPop: !widget.searching && (wide || !widget.selected),
            onPopInvokedWithResult: (popped, result) {
              if (!popped) widget.onBack();
            },
            child: wide
                ? Stack(
                    children: [
                      Row(
                        children: [
                          SizedBox(width: left, child: widget.left),
                          Expanded(
                            child: widget.selected
                                ? widget.details(false)
                                : widget.placeholder,
                          ),
                        ],
                      ),
                      Positioned(
                        left: left - 3,
                        top: 0,
                        bottom: 0,
                        width: 6,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (d) => setState(
                              () => _ratio =
                                  (left + d.delta.dx).clamp(
                                    _leftMinimum,
                                    width - _mainMinimum,
                                  ) /
                                  width,
                            ),
                            child: const Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 1,
                                height: double.infinity,
                                child: ColoredBox(color: Tg.divider),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : widget.selected
                ? widget.details(true)
                : widget.left,
          );
        },
      ),
    ),
  );
}
