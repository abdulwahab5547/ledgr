import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_typography.dart';

/// Solid lime CTA button. The primary action throughout the app.
class LedgrPrimaryButton extends StatelessWidget {
  const LedgrPrimaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.flex,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Pass a flex factor to use this button inside a `Row` of buttons (e.g.
  /// settle confirmation sheet uses 1.4). When omitted, sizes to its
  /// content with horizontal stretch.
  final int? flex;

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: LedgrColors.lime,
          foregroundColor: LedgrColors.bg,
          disabledBackgroundColor: LedgrColors.hairline2,
          disabledForegroundColor: LedgrColors.textMute,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: LedgrColors.bg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: LedgrType.sans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LedgrColors.bg,
              ),
            ),
          ],
        ),
      ),
    );
    return flex == null ? btn : Expanded(flex: flex!, child: btn);
  }
}

/// Translucent secondary action — used as the "Cancel" partner to a
/// LedgrPrimaryButton.
class LedgrSecondaryButton extends StatelessWidget {
  const LedgrSecondaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.flex,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final int? flex;

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0x0FFFFFFF),
          foregroundColor: LedgrColors.text,
          side: const BorderSide(color: LedgrColors.hairline2, width: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: LedgrColors.text),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: LedgrType.sans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: LedgrColors.text,
              ),
            ),
          ],
        ),
      ),
    );
    return flex == null ? btn : Expanded(flex: flex!, child: btn);
  }
}

/// Compact dual-action row used inside list cards (Settle / Remind).
class LedgrInlineAction extends StatelessWidget {
  const LedgrInlineAction({
    required this.label,
    required this.icon,
    this.onPressed,
    this.emphasised = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    if (emphasised) {
      return Material(
        color: LedgrColors.lime,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: LedgrColors.bg),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: LedgrType.sans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: LedgrColors.bg,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: LedgrColors.hairline2, width: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: LedgrColors.textDim),
              const SizedBox(width: 5),
              Text(
                label,
                style: LedgrType.sans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: LedgrColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

