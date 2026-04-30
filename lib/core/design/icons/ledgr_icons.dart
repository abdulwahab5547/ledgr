import 'package:flutter/material.dart';

/// Custom-painted line icons matching the design bundle's SVG paths
/// (1.6 stroke, round caps/joins). Used for the three signature tab icons:
/// vault (a locker with a dial), ledger (a bookmarked book), and pulse
/// (a heart-rate trace).
class LedgrIcons {
  const LedgrIcons._();

  static Widget vault({double size = 22, Color color = Colors.white}) =>
      _StrokeIcon(size: size, color: color, painter: _VaultPainter(color));

  static Widget ledger({double size = 22, Color color = Colors.white}) =>
      _StrokeIcon(size: size, color: color, painter: _LedgerPainter(color));

  static Widget pulse({double size = 22, Color color = Colors.white}) =>
      _StrokeIcon(size: size, color: color, painter: _PulsePainter(color));
}

class _StrokeIcon extends StatelessWidget {
  const _StrokeIcon({
    required this.size,
    required this.color,
    required this.painter,
  });
  final double size;
  final Color color;
  final CustomPainter painter;
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: painter));
}

abstract class _StrokePainter extends CustomPainter {
  _StrokePainter(this.color);
  final Color color;
  final double strokeWidth = 1.6;

  Paint get _paint => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Convert a 24x24 viewBox path coordinate to canvas coordinates.
  Offset _scale(Size size, double x, double y) =>
      Offset(x * size.width / 24, y * size.height / 24);

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _VaultPainter extends _StrokePainter {
  _VaultPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = _paint;
    // rect(3,5)-(21,19) rx=2
    final rect = Rect.fromLTRB(
      _scale(size, 3, 5).dx,
      _scale(size, 3, 5).dy,
      _scale(size, 21, 19).dx,
      _scale(size, 21, 19).dy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 2 / 24)),
      paint,
    );
    // dial circle
    canvas.drawCircle(_scale(size, 12, 12), size.width * 3.5 / 24, paint);
    // tick marks
    for (final pair in const [
      [12.0, 8.5, 12.0, 9.5],
      [12.0, 14.5, 12.0, 15.5],
      [8.5, 12.0, 9.5, 12.0],
      [14.5, 12.0, 15.5, 12.0],
    ]) {
      canvas.drawLine(
        _scale(size, pair[0], pair[1]),
        _scale(size, pair[2], pair[3]),
        paint,
      );
    }
  }
}

class _LedgerPainter extends _StrokePainter {
  _LedgerPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = _paint;
    // bookmarked outline: M16 4 H6 a2 2 0 00-2 2 v14 l3-2 3 2 3-2 3 2 V6 a2 2 0 00-2-2 z
    final outline = Path()
      ..moveTo(_scale(size, 16, 4).dx, _scale(size, 16, 4).dy)
      ..lineTo(_scale(size, 6, 4).dx, _scale(size, 6, 4).dy)
      ..cubicTo(
        _scale(size, 4.9, 4).dx,
        _scale(size, 4.9, 4).dy,
        _scale(size, 4, 4.9).dx,
        _scale(size, 4, 4.9).dy,
        _scale(size, 4, 6).dx,
        _scale(size, 4, 6).dy,
      )
      ..lineTo(_scale(size, 4, 20).dx, _scale(size, 4, 20).dy)
      ..lineTo(_scale(size, 7, 18).dx, _scale(size, 7, 18).dy)
      ..lineTo(_scale(size, 10, 20).dx, _scale(size, 10, 20).dy)
      ..lineTo(_scale(size, 13, 18).dx, _scale(size, 13, 18).dy)
      ..lineTo(_scale(size, 16, 20).dx, _scale(size, 16, 20).dy)
      ..lineTo(_scale(size, 19, 18).dx, _scale(size, 19, 18).dy)
      ..lineTo(_scale(size, 20, 20).dx, _scale(size, 20, 20).dy)
      ..lineTo(_scale(size, 20, 6).dx, _scale(size, 20, 6).dy)
      ..cubicTo(
        _scale(size, 20, 4.9).dx,
        _scale(size, 20, 4.9).dy,
        _scale(size, 19.1, 4).dx,
        _scale(size, 19.1, 4).dy,
        _scale(size, 18, 4).dx,
        _scale(size, 18, 4).dy,
      )
      ..close();
    canvas.drawPath(outline, paint);
    canvas.drawLine(_scale(size, 8, 9), _scale(size, 16, 9), paint);
    canvas.drawLine(_scale(size, 8, 13), _scale(size, 14, 13), paint);
  }
}

class _PulsePainter extends _StrokePainter {
  _PulsePainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = _paint;
    final path = Path()
      ..moveTo(_scale(size, 3, 12).dx, _scale(size, 3, 12).dy)
      ..lineTo(_scale(size, 7, 12).dx, _scale(size, 7, 12).dy)
      ..lineTo(_scale(size, 9, 5).dx, _scale(size, 9, 5).dy)
      ..lineTo(_scale(size, 13, 19).dx, _scale(size, 13, 19).dy)
      ..lineTo(_scale(size, 15, 12).dx, _scale(size, 15, 12).dy)
      ..lineTo(_scale(size, 21, 12).dx, _scale(size, 21, 12).dy);
    canvas.drawPath(path, paint);
  }
}
