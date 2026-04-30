import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_radii.dart';

/// Soft tactile card — translucent gradient surface, hairline border, top
/// inner shadow. Mirrors `Card()` in the design bundle.
class LedgrCard extends StatelessWidget {
  const LedgrCard({
    required this.child,
    this.padding = 18,
    this.gradient,
    this.onTap,
    this.borderRadius,
    super.key,
  });

  /// Convenience for when [child] handles its own padding (e.g. lists).
  const LedgrCard.flush({
    required this.child,
    this.gradient,
    this.onTap,
    this.borderRadius,
    super.key,
  }) : padding = 0;

  final Widget child;
  final double padding;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  static const Gradient _defaultGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x0BFFFFFF), Color(0x05FFFFFF)],
  );

  /// Lime-tinted hero gradient used by the True Liquidity card.
  static const Gradient heroLimeGradient = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.5, 1),
    stops: [0, 0.28, 1],
    colors: [
      Color(0x0FC9FF5E),
      Color(0x0AFFFFFF),
      Color(0x05FFFFFF),
    ],
  );

  /// Soft green tint for Lent summary card.
  static const Gradient posTintGradient = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.5, 1),
    colors: [Color(0x149BE36A), Color(0x059BE36A)],
  );

  /// Soft red tint for Borrowed summary card.
  static const Gradient negTintGradient = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.5, 1),
    colors: [Color(0x14FF8A6E), Color(0x05FF8A6E)],
  );

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(LedgrRadii.card);
    final card = Container(
      decoration: BoxDecoration(
        gradient: gradient ?? _defaultGradient,
        border: Border.all(color: LedgrColors.hairline, width: 0.5),
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: const Border(
          top: BorderSide(color: Color(0x0AFFFFFF), width: 1),
        ),
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
