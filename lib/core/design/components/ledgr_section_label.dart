import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_typography.dart';

/// Section header used between cards — italic serif on the left, mono caps
/// metadata on the right (e.g. "*Assets*  ·  5 ACCOUNTS").
class LedgrSectionLabel extends StatelessWidget {
  const LedgrSectionLabel({
    required this.label,
    this.trailing,
    super.key,
  });

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 20, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label,
              style: LedgrType.serif(
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!.toUpperCase(),
              style: LedgrType.mono(
                fontSize: 11,
                color: LedgrColors.textMute,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }
}
