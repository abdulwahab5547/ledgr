import 'package:flutter/services.dart';

/// Thin wrapper over [HapticFeedback] so call sites read intent-first.
class Haptics {
  const Haptics._();

  static Future<void> success() => HapticFeedback.mediumImpact();
  static Future<void> tap() => HapticFeedback.selectionClick();
  static Future<void> warn() => HapticFeedback.heavyImpact();
}
