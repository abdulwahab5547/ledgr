import 'dart:ui';

import 'package:flutter/material.dart';

import '../ledgr_colors.dart';

/// 40x40 round translucent button used in screen headers. Optional small
/// dot indicator (top-right) for unread state.
class LedgrIconButton extends StatelessWidget {
  const LedgrIconButton({
    required this.child,
    this.onTap,
    this.indicator = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool indicator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: const Color(0x0DFFFFFF),
                  shape: const CircleBorder(
                    side: BorderSide(color: LedgrColors.hairline2, width: 0.5),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: Center(child: child),
                  ),
                ),
              ),
            ),
          ),
          if (indicator)
            const Positioned(
              top: 9,
              right: 9,
              child: _Dot(),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: LedgrColors.lime,
        shape: BoxShape.circle,
      ),
    );
  }
}
