import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { success, failed, unavailable, cancelled }

/// Wraps [LocalAuthentication] so callers don't depend on the plugin directly
/// and tests can inject a fake.
class BiometricGate {
  BiometricGate({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<BiometricResult> authenticate({
    String reason = 'Unlock Ledgr',
  }) async {
    try {
      if (!await isAvailable()) return BiometricResult.unavailable;
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return BiometricResult.unavailable;
      }
      return BiometricResult.cancelled;
    } on MissingPluginException {
      return BiometricResult.unavailable;
    }
  }
}

final biometricGateProvider = Provider<BiometricGate>(
  (ref) => BiometricGate(),
);

/// Tracks whether the current session is unlocked. Reset on cold start and
/// on app resume (handled by [AppLifecycleObserver] in main.dart).
class UnlockState extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;
  void lock() => state = false;
}

final unlockStateProvider = NotifierProvider<UnlockState, bool>(UnlockState.new);
