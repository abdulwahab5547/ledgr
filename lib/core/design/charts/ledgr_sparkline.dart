import 'package:flutter/material.dart';

import '../ledgr_colors.dart';

/// Sparkline with a soft lime gradient fill, line stroke, and an end-point
/// marker. Used in the True Liquidity hero card.
class LedgrSparkline extends StatelessWidget {
  const LedgrSparkline({
    required this.points,
    this.height = 48,
    this.lineColor = LedgrColors.lime,
    super.key,
  });

  final List<double> points;
  final double height;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(points: points, lineColor: lineColor),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points, required this.lineColor});
  final List<double> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final minV = points.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : maxV - minV;
    final w = size.width;
    final h = size.height;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * w;
      final y = h - ((points[i] - minV) / range) * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fill, fillPaint);

    final stroke = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);

    // End marker
    final lastX = w;
    final lastY = h - ((points.last - minV) / range) * h;
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points || old.lineColor != lineColor;
}
