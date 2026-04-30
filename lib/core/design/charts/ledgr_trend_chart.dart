import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ledgr_colors.dart';

class TrendPoint {
  const TrendPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

/// Single-line trend chart with soft area fill, three x-axis date labels
/// (oldest / mid / latest), and minimal gridlines. Used by the Analytics
/// screen to render the historical Net Position trend.
class LedgrTrendChart extends StatelessWidget {
  const LedgrTrendChart({
    required this.points,
    this.height = 140,
    this.lineColor = LedgrColors.lime,
    super.key,
  });

  final List<TrendPoint> points;
  final double height;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(points: points, lineColor: lineColor),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points, required this.lineColor});
  final List<TrendPoint> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    const padTop = 14.0;
    const padBottom = 24.0;
    final w = size.width;
    final chartH = size.height - padTop - padBottom;

    final minV = points.fold<double>(
      points.first.value,
      (a, p) => p.value < a ? p.value : a,
    );
    final maxV = points.fold<double>(
      points.first.value,
      (a, p) => p.value > a ? p.value : a,
    );
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : maxV - minV;

    double xAt(int i) => (i / (points.length - 1)) * w;
    double yAt(double v) =>
        padTop + (1 - (v - minV) / range) * chartH;

    // Gridlines.
    final gridPaint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1;
    for (final g in const [0.25, 0.5, 0.75]) {
      final y = padTop + g * chartH;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(xAt(i), yAt(points[i].value));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    // Soft area fill.
    final fill = Path.from(path)
      ..lineTo(w, padTop + chartH)
      ..lineTo(0, padTop + chartH)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.22),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // End marker.
    final last = Offset(xAt(points.length - 1), yAt(points.last.value));
    canvas.drawCircle(last, 3, Paint()..color = lineColor);

    // Axis labels: first, mid, last.
    final labelStyle = GoogleFonts.jetBrainsMono(
      color: LedgrColors.textMute,
      fontSize: 9.5,
    );
    void drawLabel(int idx, double xPos, TextAlign align) {
      final tp = TextPainter(
        text: TextSpan(text: _shortDate(points[idx].date), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = align == TextAlign.left
          ? 0.0
          : align == TextAlign.right
              ? -tp.width
              : -tp.width / 2;
      tp.paint(canvas, Offset(xPos + dx, size.height - 14));
    }

    drawLabel(0, xAt(0), TextAlign.left);
    final mid = points.length ~/ 2;
    drawLabel(mid, xAt(mid), TextAlign.center);
    drawLabel(points.length - 1, xAt(points.length - 1), TextAlign.right);
  }

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]}';

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.points != points || old.lineColor != lineColor;
}
