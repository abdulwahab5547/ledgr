import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_typography.dart';

/// Circular avatar with up-to-2-letter initials and a deterministic hue from
/// the name (so the same person always gets the same color).
class LedgrAvatar extends StatelessWidget {
  const LedgrAvatar({
    required this.name,
    this.size = 38,
    super.key,
  });

  final String name;
  final double size;

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p.characters.first).join();
    return letters.toUpperCase();
  }

  int get _hue {
    var h = 0;
    for (final ch in name.codeUnits) {
      h = (h * 31 + ch) % 360;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final hue = _hue.toDouble();
    final base = HSLColor.fromAHSL(1, hue, 0.38, 0.22).toColor();
    final shade = HSLColor.fromAHSL(1, (hue + 30) % 360, 0.32, 0.14).toColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, shade],
        ),
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: LedgrColors.hairline2, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: LedgrType.sans(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
