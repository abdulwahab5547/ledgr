import 'package:flutter/material.dart';

import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/privacy/private_text.dart';

/// Two side-by-side bento cards — Burn Rate + Runway.
///
/// These are placeholder metrics until Module 4 (Pipeline & Burn) is wired.
/// The numbers come from real data once the burn-rate / runway providers
/// land; for now we accept fixed values from the Vault screen.
class BentoStats extends StatelessWidget {
  const BentoStats({
    required this.burnLakhsPerMonth,
    required this.burnDeltaPct,
    required this.runwayMonths,
    required this.runwayCap,
    this.runwayUnknown = false,
    super.key,
  });

  final double burnLakhsPerMonth;
  final double burnDeltaPct;
  final int runwayMonths;

  /// Total cells in the runway visual; runwayMonths fills from the left.
  final int runwayCap;

  /// True when runway can't be computed (no recurring expenses yet). The
  /// widget renders a dash instead of a misleading "0 months".
  final bool runwayUnknown;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LedgrCard(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BURN RATE',
                    style: LedgrType.eyebrow(
                      fontSize: 10.5,
                      letterSpacing: 1.1,
                      color: LedgrColors.textMute,
                    ),),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    PrivateText.digits(
                      burnLakhsPerMonth <= 0
                          ? '—'
                          : burnLakhsPerMonth.toStringAsFixed(1),
                      style: LedgrType.serif(fontSize: 26),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'L/mo',
                      style: LedgrType.sans(
                        fontSize: 12,
                        color: LedgrColors.textDim,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (burnDeltaPct == 0)
                  Text(
                    burnLakhsPerMonth <= 0
                        ? 'Add a recurring expense'
                        : 'monthly equivalent',
                    style: LedgrType.sans(
                      fontSize: 11,
                      color: LedgrColors.textMute,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        '${burnDeltaPct < 0 ? '−' : '+'}${burnDeltaPct.abs().toStringAsFixed(1)}%',
                        style: LedgrType.sans(
                          fontSize: 11,
                          color: burnDeltaPct < 0
                              ? LedgrColors.pos
                              : LedgrColors.neg,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'vs Mar',
                        style: LedgrType.sans(
                          fontSize: 11,
                          color: LedgrColors.textDim,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LedgrCard(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RUNWAY',
                    style: LedgrType.eyebrow(
                      fontSize: 10.5,
                      letterSpacing: 1.1,
                      color: LedgrColors.textMute,
                    ),),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    PrivateText.digits(
                      runwayUnknown
                          ? '—'
                          : (runwayMonths > 99 ? '99+' : '$runwayMonths'),
                      style: LedgrType.serif(fontSize: 26),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'months',
                      style: LedgrType.sans(
                        fontSize: 12,
                        color: LedgrColors.textDim,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 4,
                  child: Row(
                    children: [
                      for (var i = 0; i < runwayCap; i++) ...[
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: !runwayUnknown && i < runwayMonths
                                  ? LedgrColors.lime
                                  : LedgrColors.hairline2,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (i < runwayCap - 1) const SizedBox(width: 2),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
