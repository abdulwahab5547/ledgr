import 'package:flutter/material.dart';

import '../../../../core/design/charts/ledgr_flow_chart.dart';
import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/money/pkr_format.dart';
import '../../../../core/privacy/private_text.dart';

/// Projected Net Flow hero card — serif net amount + cumulative line chart.
class ProjectedFlowCard extends StatelessWidget {
  const ProjectedFlowCard({
    required this.incomingMinor,
    required this.outgoingMinor,
    required this.days,
    required this.xLabels,
    super.key,
  });

  final int incomingMinor;
  final int outgoingMinor;
  final List<FlowDay> days;
  final Map<int, String> xLabels;

  int get netMinor => incomingMinor - outgoingMinor;

  @override
  Widget build(BuildContext context) {
    final pos = netMinor >= 0;
    return LedgrCard(
      padding: 18,
      gradient: LedgrCard.heroLimeGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROJECTED NET FLOW',
                      style: LedgrType.eyebrow(letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${pos ? '+' : '−'} Rs',
                            style: LedgrType.serif(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: LedgrColors.textDim,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        PrivateText.digits(
                          PkrFormat.fromMinor(
                            netMinor.abs(),
                            includeSymbol: false,
                          ),
                          style: LedgrType.serif(
                            fontSize: 38,
                            height: 38,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Legend(
                    color: LedgrColors.lime,
                    label: 'In',
                    value: PkrFormat.fromMinor(
                      incomingMinor,
                      includeSymbol: false,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _Legend(
                    color: LedgrColors.neg,
                    label: 'Out',
                    value: PkrFormat.fromMinor(
                      outgoingMinor,
                      includeSymbol: false,
                    ),
                    dashed: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          LedgrFlowChart(days: days, xLabels: xLabels),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final String value;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 6,
          child: CustomPaint(
            painter: _LegendLinePainter(color: color, dashed: dashed),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: LedgrType.eyebrow(
            fontSize: 10.5,
            color: LedgrColors.textMute,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),
        PrivateText.digits(
          value,
          style: LedgrType.mono(fontSize: 11, color: LedgrColors.textDim),
        ),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  _LegendLinePainter({required this.color, required this.dashed});
  final Color color;
  final bool dashed;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (!dashed) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    } else {
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset((x + 2).clamp(0, size.width), size.height / 2),
          paint,
        );
        x += 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter old) =>
      old.color != color || old.dashed != dashed;
}
