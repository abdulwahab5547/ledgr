import 'package:flutter/material.dart';

import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/pkr_format.dart';
import '../../../../core/privacy/private_text.dart';

/// Lent vs Borrowed pair of summary cards used at the top of the Ledger
/// screen.
class TwinTotals extends StatelessWidget {
  const TwinTotals({
    required this.lent,
    required this.borrowed,
    required this.lentCount,
    required this.borrowedCount,
    super.key,
  });

  final Money lent;
  final Money borrowed;
  final int lentCount;
  final int borrowedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TotalCard(
            label: 'LENT',
            color: LedgrColors.pos,
            gradient: LedgrCard.posTintGradient,
            amount: lent,
            count: lentCount,
            arrow: Icons.arrow_outward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TotalCard(
            label: 'BORROWED',
            color: LedgrColors.neg,
            gradient: LedgrCard.negTintGradient,
            amount: borrowed,
            count: borrowedCount,
            arrow: Icons.south_west,
          ),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.color,
    required this.gradient,
    required this.amount,
    required this.count,
    required this.arrow,
  });

  final String label;
  final Color color;
  final Gradient gradient;
  final Money amount;
  final int count;
  final IconData arrow;

  @override
  Widget build(BuildContext context) {
    return LedgrCard(
      padding: 16,
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(arrow, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: LedgrType.eyebrow(
                  fontSize: 10.5,
                  color: color,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PrivateText.digits(
            amount.currencyCode == 'PKR' ? PkrFormat.money(amount) : amount.format(),
            style: LedgrType.serif(fontSize: 24),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            count == 1 ? '1 PERSON' : '$count PEOPLE',
            style: LedgrType.mono(fontSize: 11, color: LedgrColors.textMute),
          ),
        ],
      ),
    );
  }
}
