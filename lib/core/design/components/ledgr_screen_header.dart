import 'package:flutter/material.dart';

import '../ledgr_colors.dart';
import '../ledgr_typography.dart';

/// Standard screen header — eyebrow label up top, editorial serif title
/// underneath, plus optional trailing slot for IconBtn(s).
///
/// Title supports a leading italic fragment (e.g. "Good evening,") followed
/// by a regular fragment (e.g. " Hassan").
class LedgrScreenHeader extends StatelessWidget {
  const LedgrScreenHeader({
    required this.eyebrow,
    required this.titleRegular,
    this.titleItalic,
    this.italicLeading = true,
    this.trailing,
    super.key,
  });

  final String eyebrow;
  final String? titleItalic;
  final String titleRegular;

  /// When true, italic part comes first (e.g. "*Good evening,* Hassan");
  /// when false, regular leads (e.g. "Net Rs 1,23,456").
  final bool italicLeading;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final regular = TextSpan(
      text: titleRegular,
      style: LedgrType.headlineSerif(),
    );
    final italic = titleItalic == null
        ? null
        : TextSpan(
            text: titleItalic,
            style: LedgrType.editorialItalic(),
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
              const SizedBox(height: 4),
              RichText(
                text: italic == null
                    ? regular
                    : (italicLeading
                        ? TextSpan(children: [italic, regular])
                        : TextSpan(children: [regular, italic])),
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
