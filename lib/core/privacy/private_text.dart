import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'privacy_provider.dart';

/// Renders monetary text that automatically masks itself when the global
/// privacy mode ("Ghost Toggle") is on.
///
/// Two modes:
/// - [PrivateText.digits] replaces every digit in [text] with '•' so
///   currency symbols, separators, and signs stay visible (this matches the
///   design bundle's `maskFigures` helper).
/// - [PrivateText.bullets] renders a fixed-length string of '•' (e.g. "••••")
///   when private; otherwise renders [text] verbatim.
class PrivateText extends ConsumerWidget {
  const PrivateText.digits(
    this.text, {
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  })  : _bulletCount = null,
        _mode = _PrivateMode.digits;

  const PrivateText.bullets({
    required String visible,
    required int bulletCount,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  })  : text = visible,
        _bulletCount = bulletCount,
        _mode = _PrivateMode.bullets;

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final int? _bulletCount;
  final _PrivateMode _mode;

  static String maskDigits(String input) =>
      input.replaceAll(RegExp(r'\d'), '•');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masked = ref.watch(privacyModeProvider);
    final out = !masked
        ? text
        : _mode == _PrivateMode.digits
            ? maskDigits(text)
            : '•' * (_bulletCount ?? 4);
    return Text(
      out,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

enum _PrivateMode { digits, bullets }
