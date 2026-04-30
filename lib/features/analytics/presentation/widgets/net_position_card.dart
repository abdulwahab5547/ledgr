import 'package:flutter/material.dart';

import '../../../../core/design/charts/ledgr_trend_chart.dart';
import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/money/pkr_format.dart';
import '../../../../core/privacy/private_text.dart';
import '../../data/net_position_snapshot_model.dart';

class NetPositionCard extends StatelessWidget {
  const NetPositionCard({required this.snapshots, super.key});

  final List<NetPositionSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    if (snapshots.length < 2) {
      return _Empty(snapshots: snapshots);
    }
    final latest = snapshots.last.netAssetsMinor;
    final earliest = snapshots.first.netAssetsMinor;
    final delta = latest - earliest;
    final pos = delta >= 0;
    final pct = earliest == 0
        ? 0.0
        : (delta / earliest.abs()) * 100;

    return LedgrCard(
      padding: 18,
      gradient: LedgrCard.heroLimeGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NET POSITION',
                style: LedgrType.eyebrow(letterSpacing: 1.2),
              ),
              Text(
                '${snapshots.length}d HISTORY',
                style: LedgrType.mono(
                  fontSize: 11,
                  color: LedgrColors.textMute,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 6),
                child: Text(
                  'Rs',
                  style: LedgrType.serif(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: LedgrColors.textDim,
                  ),
                ),
              ),
              Expanded(
                child: PrivateText.digits(
                  PkrFormat.fromMinor(latest, includeSymbol: false),
                  style: LedgrType.serif(
                    fontSize: 38,
                    height: 38,
                    letterSpacing: -1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _DeltaPill(positive: pos, pct: pct),
            ],
          ),
          const SizedBox(height: 10),
          LedgrTrendChart(
            points: [
              for (final s in snapshots)
                TrendPoint(
                  date: NetPositionSnapshot.parseDateKey(s.dateKey),
                  value: s.netAssetsMinor.toDouble(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.snapshots});
  final List<NetPositionSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return LedgrCard(
      padding: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NET POSITION',
            style: LedgrType.eyebrow(letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            snapshots.isEmpty
                ? 'No history yet'
                : 'Need at least 2 days to draw a trend',
            style: LedgrType.serif(fontSize: 18, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 4),
          Text(
            snapshots.isEmpty
                ? 'Snapshots are captured automatically once a day. Come back tomorrow to see your trend take shape.'
                : 'Your second daily snapshot will land tomorrow — the line chart kicks in once there are two points to connect.',
            style: LedgrType.sans(fontSize: 13, color: LedgrColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.positive, required this.pct});
  final bool positive;
  final double pct;

  @override
  Widget build(BuildContext context) {
    final color = positive ? LedgrColors.pos : LedgrColors.neg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: positive ? LedgrColors.posBg : LedgrColors.negBg,
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
          Text(
            '${pct.toStringAsFixed(1)}%',
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
