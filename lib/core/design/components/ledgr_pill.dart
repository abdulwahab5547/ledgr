import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_radii.dart';
import '../ledgr_typography.dart';

/// Tiny inline pill used for "Lent"/"Borrowed" tags and delta chips.
class LedgrPill extends StatelessWidget {
  const LedgrPill({
    required this.label,
    this.foreground = LedgrColors.text,
    this.background = LedgrColors.surfaceHi,
    this.icon,
    this.useMono = false,
    this.compact = false,
    super.key,
  });

  /// Subtle "Lent" tag — green text on green-tint background.
  const factory LedgrPill.lent() = _LentPill;

  /// Subtle "Borrowed" tag — red text on red-tint background.
  const factory LedgrPill.borrowed() = _BorrowedPill;

  final String label;
  final Color foreground;
  final Color background;
  final Widget? icon;
  final bool useMono;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = useMono
        ? LedgrType.mono(fontSize: 11, fontWeight: FontWeight.w500, color: foreground)
        : LedgrType.sans(
            fontSize: compact ? 9.5 : 11,
            fontWeight: FontWeight.w600,
            color: foreground,
            letterSpacing: 0.8,
          );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(compact ? 4 : LedgrRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 4)],
          Text(label.toUpperCase(), style: textStyle),
        ],
      ),
    );
  }
}

class _LentPill extends LedgrPill {
  const _LentPill()
      : super(
          label: 'Lent',
          foreground: LedgrColors.pos,
          background: LedgrColors.posBg,
          compact: true,
        );
}

class _BorrowedPill extends LedgrPill {
  const _BorrowedPill()
      : super(
          label: 'Borrowed',
          foreground: LedgrColors.neg,
          background: LedgrColors.negBg,
          compact: true,
        );
}
