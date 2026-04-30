import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_radii.dart';
import '../ledgr_typography.dart';

class LedgrSegment<T> {
  const LedgrSegment({required this.value, required this.label});
  final T value;
  final String label;
}

/// Pill-style segmented control used for filters (All/Lent/Borrowed) and
/// time horizons (7d/14d/30d/90d).
class LedgrSegmented<T> extends StatelessWidget {
  const LedgrSegmented({
    required this.segments,
    required this.value,
    required this.onChanged,
    this.useMonoLabel = false,
    super.key,
  });

  final List<LedgrSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Use the JetBrains Mono font for labels (used by the time-horizon picker
  /// on the Pipeline screen).
  final bool useMonoLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LedgrColors.surface,
        border: Border.all(color: LedgrColors.hairline, width: 0.5),
        borderRadius: BorderRadius.circular(LedgrRadii.segmentOuter),
      ),
      child: Row(
        children: [
          for (final seg in segments)
            Expanded(child: _SegmentButton(seg: seg, parent: this)),
        ],
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({required this.seg, required this.parent});
  final LedgrSegment<T> seg;
  final LedgrSegmented<T> parent;

  @override
  Widget build(BuildContext context) {
    final selected = seg.value == parent.value;
    final label = parent.useMonoLabel
        ? LedgrType.mono(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: selected ? LedgrColors.text : LedgrColors.textDim,
            letterSpacing: 0.5,
          )
        : LedgrType.sans(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: selected ? LedgrColors.text : LedgrColors.textDim,
            letterSpacing: -0.1,
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => parent.onChanged(seg.value),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: parent.useMonoLabel ? 7 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0x12FFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(LedgrRadii.segmentInner),
          border: selected
              ? Border.all(color: LedgrColors.hairline2, width: 0.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          parent.useMonoLabel ? seg.label.toUpperCase() : seg.label,
          style: label,
        ),
      ),
    );
  }
}
