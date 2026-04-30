import 'dart:ui';

import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_radii.dart';

/// Glassmorphic bar — backdrop-blurred, translucent, used for the bottom
/// tab bar. Mirrors `GlassBar()` in the design bundle.
class LedgrGlassBar extends StatelessWidget {
  const LedgrGlassBar({
    required this.child,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(LedgrRadii.sheet);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xA6141518),
            border: Border.all(color: LedgrColors.hairline2, width: 0.5),
            borderRadius: radius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: const Border(
              top: BorderSide(color: Color(0x14FFFFFF), width: 1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
