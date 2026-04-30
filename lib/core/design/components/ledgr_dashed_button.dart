import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_radii.dart';
import '../ledgr_typography.dart';

/// Full-width "Add / Link / etc." action — dashed hairline border, dim text,
/// optional leading icon. Matches the "Link account" button on the Vault.
class LedgrDashedButton extends StatelessWidget {
  const LedgrDashedButton({
    required this.label,
    this.icon,
    this.onPressed,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(LedgrRadii.cardInner),
        child: InkWell(
          borderRadius: BorderRadius.circular(LedgrRadii.cardInner),
          onTap: onPressed,
          child: CustomPaint(
            painter: _DashedRectPainter(
              color: LedgrColors.hairline2,
              radius: LedgrRadii.cardInner,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: LedgrColors.textDim),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: LedgrType.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: LedgrColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      var distance = 0.0;
      while (distance < m.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          m.extractPath(distance, next.clamp(0, m.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
