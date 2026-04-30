import 'package:flutter/material.dart';

import '../../../../core/design/charts/ledgr_donut.dart';
import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/privacy/private_text.dart';

class AllocationCard extends StatelessWidget {
  const AllocationCard({
    required this.segments,
    required this.totalLabel,
    super.key,
  });

  final List<DonutSegment> segments;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return LedgrCard(
        padding: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ALLOCATION',
              style: LedgrType.eyebrow(letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              'Add an account in the Vault to see how your liquidity is split.',
              style: LedgrType.sans(fontSize: 13, color: LedgrColors.textDim),
            ),
          ],
        ),
      );
    }
    final total = segments.fold<num>(0, (a, b) => a + b.value);
    return LedgrCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALLOCATION',
            style: LedgrType.eyebrow(letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              LedgrDonut(
                segments: segments,
                size: 128,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrivateText.digits(
                      totalLabel,
                      style: LedgrType.serif(fontSize: 22, height: 22),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TOTAL',
                      style: LedgrType.eyebrow(
                        fontSize: 9.5,
                        color: LedgrColors.textMute,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    for (final s in segments.take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: s.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.label,
                                style: LedgrType.sans(
                                  fontSize: 12.5,
                                  color: LedgrColors.text,
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(s.value / total * 100).round()}%',
                              style: LedgrType.mono(
                                fontSize: 11.5,
                                color: LedgrColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
