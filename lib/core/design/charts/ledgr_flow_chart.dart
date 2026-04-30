import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ledgr_colors.dart';

/// Daily flow buckets — used by the projected net-flow chart on the Pipeline
/// screen. The chart plots cumulative incoming vs cumulative outgoing.
class FlowDay {
  const FlowDay({required this.label, required this.incoming, required this.outgoing});
  final String label;
  final int incoming;
  final int outgoing;
}

/// Cumulative incoming/outgoing over a day window. Solid lime line for
/// incoming with soft area fill, dashed coral line for outgoing. Markers
/// on days with non-zero incoming.
class LedgrFlowChart extends StatelessWidget {
  const LedgrFlowChart({
    required this.days,
    required this.xLabels,
    this.height = 130,
    super.key,
  });

  final List<FlowDay> days;

  /// Map of day index → label (e.g. {0: '30 APR', 6: '06 MAY', 13: '13 MAY'}).
  final Map<int, String> xLabels;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _FlowChartPainter(days: days, xLabels: xLabels),
      ),
    );
  }
}

class _FlowChartPainter extends CustomPainter {
  _FlowChartPainter({required this.days, required this.xLabels});
  final List<FlowDay> days;
  final Map<int, String> xLabels;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    const padTop = 12.0;
    const padBottom = 22.0;
    final chartH = size.height - padTop - padBottom;
    final w = size.width;

    // Cumulative series.
    final cumIn = <double>[];
    final cumOut = <double>[];
    var sIn = 0;
    var sOut = 0;
    for (final d in days) {
      sIn += d.incoming;
      sOut += d.outgoing;
      cumIn.add(sIn.toDouble());
      cumOut.add(sOut.toDouble());
    }
    final peak = [...cumIn, ...cumOut].fold<double>(0, (a, b) => b > a ? b : a);
    final safePeak = peak == 0 ? 1.0 : peak;

    double xAt(int i) => (i / (days.length - 1)) * w;
    double yAt(double v) => padTop + (1 - v / safePeak) * chartH;

    // Gridlines.
    final gridPaint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1;
    for (final g in const [0.25, 0.5, 0.75]) {
      final y = padTop + g * chartH;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Build paths.
    final inPath = Path();
    final outPath = Path();
    for (var i = 0; i < days.length; i++) {
      final x = xAt(i);
      final yIn = yAt(cumIn[i]);
      final yOut = yAt(cumOut[i]);
      if (i == 0) {
        inPath.moveTo(x, yIn);
        outPath.moveTo(x, yOut);
      } else {
        inPath.lineTo(x, yIn);
        outPath.lineTo(x, yOut);
      }
    }

    // Incoming area fill.
    final fill = Path.from(inPath)
      ..lineTo(xAt(days.length - 1), padTop + chartH)
      ..lineTo(xAt(0), padTop + chartH)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LedgrColors.lime.withValues(alpha: 0.22),
            LedgrColors.lime.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, size.height)),
    );

    // Incoming line.
    canvas.drawPath(
      inPath,
      Paint()
        ..color = LedgrColors.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Outgoing dashed line.
    _drawDashed(
      canvas,
      outPath,
      Paint()
        ..color = LedgrColors.neg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      dash: 3,
      gap: 3,
    );

    // Markers on incoming days.
    for (var i = 0; i < days.length; i++) {
      if (days[i].incoming > 0) {
        final p = Offset(xAt(i), yAt(cumIn[i]));
        canvas.drawCircle(p, 3.5, Paint()..color = LedgrColors.bg);
        canvas.drawCircle(
          p,
          3.5,
          Paint()
            ..color = LedgrColors.lime
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }

    // X-axis labels.
    final labelStyle = GoogleFonts.jetBrainsMono(
      color: LedgrColors.textMute,
      fontSize: 9.5,
    );
    xLabels.forEach((idx, text) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = xAt(idx);
      double dx;
      if (idx == 0) {
        dx = 0;
      } else if (idx == days.length - 1) {
        dx = -tp.width;
      } else {
        dx = -tp.width / 2;
      }
      tp.paint(canvas, Offset(x + dx, size.height - 14));
    });
  }

  void _drawDashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dash = 4,
    double gap = 4,
  }) {
    for (final m in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < m.length) {
        final next = (distance + dash).clamp(0, m.length);
        canvas.drawPath(m.extractPath(distance, next.toDouble()), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlowChartPainter old) =>
      old.days != days || old.xLabels != xLabels;
}
