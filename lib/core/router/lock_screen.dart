import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/ambient_backdrop.dart';
import '../design/ledgr_colors.dart';
import '../design/ledgr_typography.dart';
import '../security/biometric_gate.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _attempting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
  }

  Future<void> _tryUnlock() async {
    if (_attempting) return;
    setState(() {
      _attempting = true;
      _error = null;
    });
    final gate = ref.read(biometricGateProvider);
    final result = await gate.authenticate();
    if (!mounted) return;
    switch (result) {
      case BiometricResult.success:
      case BiometricResult.unavailable:
        ref.read(unlockStateProvider.notifier).unlock();
      case BiometricResult.failed:
      case BiometricResult.cancelled:
        setState(() {
          _attempting = false;
          _error = 'Authentication required';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'L',
                    style: LedgrType.serif(
                      fontSize: 96,
                      fontStyle: FontStyle.italic,
                      color: LedgrColors.lime,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Ledgr', style: LedgrType.serif(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(
                    'Locked',
                    style: LedgrType.eyebrow(
                      color: LedgrColors.textMute,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 36),
                  FilledButton(
                    onPressed: _attempting ? null : _tryUnlock,
                    style: FilledButton.styleFrom(
                      backgroundColor: LedgrColors.lime,
                      foregroundColor: LedgrColors.bg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Unlock',
                      style: LedgrType.sans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LedgrColors.bg,
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: LedgrType.sans(
                        fontSize: 12,
                        color: LedgrColors.neg,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
