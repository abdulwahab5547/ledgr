import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'privacy_provider.dart';

/// Wrap any widget showing sensitive monetary text. When the global
/// [privacyModeProvider] is on, the child is blurred via [ImageFiltered].
class PrivacyMask extends ConsumerWidget {
  const PrivacyMask({
    required this.child,
    this.sigma = 8,
    super.key,
  });

  final Widget child;
  final double sigma;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masked = ref.watch(privacyModeProvider);
    if (!masked) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
