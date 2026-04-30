import 'package:flutter/material.dart';

import '../../../../core/design/charts/ledgr_bar_chart.dart';
import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/money/pkr_format.dart';
import '../../../../core/privacy/private_text.dart';
import '../../../pipeline/data/expense_category.dart';
import '../../domain/category_history_provider.dart';

class CategoryBarCard extends StatelessWidget {
  const CategoryBarCard({required this.totals, super.key});

  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return LedgrCard(
        padding: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CATEGORY SPEND · 30d',
              style: LedgrType.eyebrow(letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              'No outflows in the last 30 days yet.',
              style: LedgrType.sans(fontSize: 13, color: LedgrColors.textDim),
            ),
          ],
        ),
      );
    }
    final total = totals.fold<int>(0, (a, b) => a + b.minorUnits);

    return LedgrCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATEGORY SPEND · 30d',
                style: LedgrType.eyebrow(letterSpacing: 1.2),
              ),
              PrivateText.digits(
                PkrFormat.fromMinor(total),
                style: LedgrType.mono(
                  fontSize: 11.5,
                  color: LedgrColors.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LedgrBarChart(
            items: [
              for (final t in totals)
                BarItem(
                  label: t.category.label,
                  value: t.minorUnits,
                  color: t.category.color,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final t in totals)
                _LegendChip(
                  label: t.category.label,
                  amount: PkrFormat.fromMinor(
                    t.minorUnits,
                    includeSymbol: false,
                  ),
                  color: t.category.color,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: LedgrType.sans(
            fontSize: 11.5,
            color: LedgrColors.textDim,
          ),
        ),
        const SizedBox(width: 4),
        PrivateText.digits(
          amount,
          style: LedgrType.mono(
            fontSize: 11,
            color: LedgrColors.textMute,
          ),
        ),
      ],
    );
  }
}
