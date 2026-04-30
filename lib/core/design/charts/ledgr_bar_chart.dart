import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ledgr_colors.dart';

class BarItem {
  const BarItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final num value;
  final Color color;
}

/// Vertical bar chart used by the Analytics screen for category spend.
/// Bars use the per-category color. Heights are normalised against the
/// largest value so the visual stays meaningful regardless of currency size.
class LedgrBarChart extends StatelessWidget {
  const LedgrBarChart({
    required this.items,
    this.height = 200,
    this.barWidth = 22,
    this.gap = 14,
    super.key,
  });

  final List<BarItem> items;
  final double height;
  final double barWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(
          items: items,
          barWidth: barWidth,
          gap: gap,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.items,
    required this.barWidth,
    required this.gap,
  });

  final List<BarItem> items;
  final double barWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    const padTop = 12.0;
    const padBottom = 32.0;
    final chartH = size.height - padTop - padBottom;

    final maxValue = items.fold<num>(
      0,
      (a, b) => b.value > a ? b.value : a,
    );
    final safeMax = maxValue == 0 ? 1.0 : maxValue.toDouble();

    final totalBarWidth = items.length * barWidth + (items.length - 1) * gap;
    final startX = (size.width - totalBarWidth) / 2;

    final labelStyle = GoogleFonts.interTight(
      color: LedgrColors.textMute,
      fontSize: 9.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    );

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final x = startX + i * (barWidth + gap);
      final ratio = (item.value / safeMax).clamp(0.0, 1.0);
      final h = ratio * chartH;
      final top = padTop + (chartH - h);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = item.color);

      // Bottom track for visual balance even when bar is tiny.
      final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, padTop, barWidth, chartH),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        track,
        Paint()
          ..color = const Color(0x0CFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );

      // Label below bar.
      final tp = TextPainter(
        text: TextSpan(
          text: _shortLabel(item.label),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: barWidth + gap);
      tp.paint(
        canvas,
        Offset(
          x + barWidth / 2 - tp.width / 2,
          padTop + chartH + 6,
        ),
      );
    }
  }

  String _shortLabel(String label) {
    if (label.length <= 6) return label.toUpperCase();
    return '${label.substring(0, 5)}…'.toUpperCase();
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.items != items ||
      old.barWidth != barWidth ||
      old.gap != gap;
}
