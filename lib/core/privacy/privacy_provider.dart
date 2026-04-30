import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "Ghost Toggle". When true, every [PrivacyMask] in the tree blurs
/// its child so monetary values aren't readable over the user's shoulder.
class PrivacyMode extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setMasked(bool value) => state = value;
}

final privacyModeProvider = NotifierProvider<PrivacyMode, bool>(PrivacyMode.new);
