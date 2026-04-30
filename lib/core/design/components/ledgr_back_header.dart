import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_typography.dart';
import 'ledgr_icon_button.dart';

/// Standard "stack" header for full-screen detail routes (Analytics,
/// Settings). Back arrow on the left, eyebrow + serif title in the centre,
/// optional trailing IconBtn(s).
class LedgrBackHeader extends StatelessWidget {
  const LedgrBackHeader({
    required this.eyebrow,
    required this.title,
    this.trailing,
    this.onBack,
    super.key,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LedgrIconButton(
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
          child: const Icon(
            Icons.arrow_back,
            size: 18,
            color: LedgrColors.text,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: LedgrType.eyebrow(
                  fontSize: 12,
                  letterSpacing: 0.6,
                  color: LedgrColors.textMute,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: LedgrType.serif(fontSize: 26),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
