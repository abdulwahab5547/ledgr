import 'package:flutter/material.dart';

import '../../../../core/design/charts/ledgr_sparkline.dart';
import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/pkr_format.dart';
import '../../../../core/privacy/private_text.dart';
import '../../../pipeline/domain/true_liquidity_provider.dart';

/// True Liquidity hero — the headline number on the Vault. Shows the lime
/// "live" pulse, the serif amount, the 24h delta pill, and a sparkline.
class TrueLiquidityCard extends StatelessWidget {
  const TrueLiquidityCard({
    required this.total,
    required this.deltaMinor,
    required this.deltaPct,
    required this.sparkPoints,
    this.horizonDays,
    this.breakdown,
    super.key,
  });

  final Money? total;
  final int deltaMinor;
  final double deltaPct;
  final List<double> sparkPoints;

  /// When provided, renders a small "Nd window" tag next to LIVE so the user
  /// understands the headline already includes incoming/burn projections.
  final int? horizonDays;

  /// Optional component breakdown — assets/incoming/payables/burn — rendered
  /// as a single-line strip below the hero amount.
  final TrueLiquidity? breakdown;

  @override
  Widget build(BuildContext context) {
    final amountText = total == null
        ? '—'
        : PkrFormat.money(total!, includeSymbol: false);
    final deltaText = PkrFormat.fromMinor(deltaMinor.abs(), includeSymbol: false);
    final pos = deltaMinor >= 0;

    return LedgrCard(
      padding: 22,
      gradient: LedgrCard.heroLimeGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: LedgrColors.lime,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: LedgrColors.lime, blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TRUE LIQUIDITY',
                    style: LedgrType.eyebrow(letterSpacing: 1.2),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (horizonDays != null) ...[
                    Text(
                      '${horizonDays}d window',
                      style: LedgrType.mono(
                        fontSize: 11,
                        color: LedgrColors.textMute,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 2,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: LedgrColors.textFaint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'LIVE',
                    style: LedgrType.mono(
                      fontSize: 11,
                      color: LedgrColors.textMute,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 6),
                child: Text(
                  'Rs',
                  style: LedgrType.serif(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: LedgrColors.textDim,
                  ),
                ),
              ),
              Expanded(
                child: PrivateText.digits(
                  amountText,
                  style: LedgrType.heroSerif(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (deltaMinor != 0)
            Row(
              children: [
                _DeltaPill(
                  positive: pos,
                  amount: deltaText,
                  pct: deltaPct,
                ),
                const SizedBox(width: 10),
                Text(
                  'last 24h',
                  style: LedgrType.bodySmall(color: LedgrColors.textMute),
                ),
              ],
            )
          else if (breakdown != null)
            _BreakdownStrip(breakdown: breakdown!),
          const SizedBox(height: 14),
          LedgrSparkline(points: sparkPoints, height: 48),
        ],
      ),
    );
  }
}

class _BreakdownStrip extends StatelessWidget {
  const _BreakdownStrip({required this.breakdown});
  final TrueLiquidity breakdown;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: 'Assets',
          minor: breakdown.assets.minorUnits,
          color: LedgrColors.text,
        ),
        const SizedBox(width: 6),
        _Chip(
          label: 'In',
          minor: breakdown.incoming.minorUnits,
          color: LedgrColors.pos,
          prefix: '+',
        ),
        const SizedBox(width: 6),
        _Chip(
          label: 'Out',
          minor: breakdown.payables.minorUnits + breakdown.burn.minorUnits,
          color: LedgrColors.neg,
          prefix: '−',
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.minor,
    required this.color,
    this.prefix = '',
  });

  final String label;
  final int minor;
  final Color color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final lakhs = (minor / 100) / 100000;
    final formatted = lakhs >= 100
        ? '${(lakhs / 100).toStringAsFixed(1)} Cr'
        : '${lakhs.toStringAsFixed(1)} L';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x08FFFFFF),
          border: Border.all(color: LedgrColors.hairline, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: LedgrType.eyebrow(
                fontSize: 9.5,
                color: LedgrColors.textMute,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 2),
            PrivateText.digits(
              minor == 0 ? '—' : '$prefix$formatted',
              style: LedgrType.mono(fontSize: 11.5, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({
    required this.positive,
    required this.amount,
    required this.pct,
  });

  final bool positive;
  final String amount;
  final double pct;

  @override
  Widget build(BuildContext context) {
    final color = positive ? LedgrColors.pos : LedgrColors.neg;
    final bg = positive ? LedgrColors.posBg : LedgrColors.negBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.arrow_outward : Icons.south_west,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          PrivateText.digits(
            '$amount · ${pct.toStringAsFixed(2)}%',
            style: LedgrType.mono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
