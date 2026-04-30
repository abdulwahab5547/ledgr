import 'dart:math' as math;

import 'package:flutter/material.dart';

class DonutSegment {
  const DonutSegment({required this.label, required this.value, required this.color});
  final String label;
  final num value;
  final Color color;
}

/// Two-radius donut (inner cutout) used by the Pipeline screen for the
/// recurring-expenses breakdown. Pure CustomPainter — no fl_chart dependency
/// here so the visual control stays exact.
class LedgrDonut extends StatelessWidget {
  const LedgrDonut({
    required this.segments,
    this.size = 128,
    this.innerRadius = 38,
    this.outerRadius = 56,
    this.center,
    super.key,
  });

  final List<DonutSegment> segments;
  final double size;
  final double innerRadius;
  final double outerRadius;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              segments: segments,
              innerRadius: innerRadius,
              outerRadius: outerRadius,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.innerRadius,
    required this.outerRadius,
  });

  final List<DonutSegment> segments;
  final double innerRadius;
  final double outerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final total = segments.fold<num>(0, (s, x) => s + x.value);
    if (total <= 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    var acc = 0.0;
    for (final seg in segments) {
      final start = acc / total;
      acc += seg.value;
      final end = acc / total;
      final path = _ringSegment(cx, cy, start, end);
      canvas.drawPath(path, Paint()..color = seg.color);
    }
  }

  Path _ringSegment(double cx, double cy, double start, double end) {
    final a0 = start * math.pi * 2 - math.pi / 2;
    final a1 = end * math.pi * 2 - math.pi / 2;
    final r1 = innerRadius;
    final r2 = outerRadius;
    final p = Path();
    final outer = Rect.fromCircle(center: Offset(cx, cy), radius: r2);
    final inner = Rect.fromCircle(center: Offset(cx, cy), radius: r1);
    p
      ..moveTo(cx + math.cos(a0) * r2, cy + math.sin(a0) * r2)
      ..arcTo(outer, a0, a1 - a0, false)
      ..lineTo(cx + math.cos(a1) * r1, cy + math.sin(a1) * r1)
      ..arcTo(inner, a1, -(a1 - a0), false)
      ..close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments ||
      old.innerRadius != innerRadius ||
      old.outerRadius != outerRadius;
}
