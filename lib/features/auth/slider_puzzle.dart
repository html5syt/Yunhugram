import 'package:flutter/widgets.dart';
import '../../l10n/strings.dart';
import '../../ui/theme.dart';
import 'challenge.dart';

/// 自绘图像拼图的缩放布局；提交和键盘调整都使用同一实际位移。
class SliderPuzzle extends StatelessWidget {
  const SliderPuzzle({
    required this.challenge,
    required this.x,
    required this.onChanged,
    required this.strings,
    super.key,
  });
  final Challenge challenge;
  final double x;
  final ValueChanged<double> onChanged;
  final Strings strings;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final c = challenge;
      final width = constraints.maxWidth;
      final scale = width / c.width;
      final maximum = c.width - c.tileWidth;
      return Column(
        children: [
          SizedBox(
            height: c.height * scale,
            width: width,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(
                    c.background,
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                  ),
                ),
                Positioned(
                  left: x * scale,
                  top: c.tileY * scale,
                  width: c.tileWidth * scale,
                  height: c.tileHeight * scale,
                  child: Image.memory(
                    c.tile!,
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: strings('slide'),
            slider: true,
            value: '${(x / maximum * 100).round()}%',
            onIncrease: () => onChanged((x + 1).clamp(0, maximum)),
            onDecrease: () => onChanged((x - 1).clamp(0, maximum)),
            child: GestureDetector(
              onHorizontalDragUpdate: (event) =>
                  onChanged(c.rawX(x * scale + event.delta.dx, width)),
              child: SizedBox(
                height: 48,
                width: width,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Tg.grouped,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            strings('slide'),
                            style: Tg.text(13, color: Tg.muted),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: x / maximum * (width - 48),
                      child: SizedBox.square(
                        dimension: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Tg.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: TgIcon(
                              'msg_arrowright',
                              color: Tg.background,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
