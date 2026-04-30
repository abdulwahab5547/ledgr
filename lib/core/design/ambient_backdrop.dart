import 'package:flutter/material.dart';

import 'ledgr_colors.dart';

/// The cinematic ambient backdrop that sits behind every screen — a soft
/// lime glow in the upper-right and a violet glow in the lower-left, painted
/// over the deep bg color. Mirrors the radial gradients used in app.jsx.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: LedgrColors.bg),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.6, -1),
                  radius: 0.8,
                  colors: [Color(0x1AC9FF5E), Color(0x00C9FF5E)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-1, 0.6),
                  radius: 0.85,
                  colors: [Color(0x147E5BFF), Color(0x007E5BFF)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
