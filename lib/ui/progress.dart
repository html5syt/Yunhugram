import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'theme.dart';

/// 自绘圆形进度，只有动画绘制区域重绘。
class TgProgress extends StatefulWidget {
  const TgProgress({this.size = 24, this.color = Tg.blue, super.key});
  final double size;
  final Color color;
  @override
  State<TgProgress> createState() => _TgProgressState();
}

class _TgProgressState extends State<TgProgress>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: RepaintBoundary(
      child: CustomPaint(painter: _ProgressPainter(_animation, widget.color)),
    ),
  );
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter(this.animation, this.color) : super(repaint: animation);
  final Animation<double> animation;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      (Offset.zero & size).deflate(2),
      animation.value * math.pi * 2,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressPainter old) => old.color != color;
}
