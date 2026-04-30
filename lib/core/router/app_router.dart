import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/ambient_backdrop.dart';
import '../design/components/ledgr_glass_bar.dart';
import '../design/icons/ledgr_icons.dart';
import '../design/ledgr_colors.dart';
import '../design/ledgr_typography.dart';
import '../security/biometric_gate.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/auth/domain/auth_providers.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/ledger/presentation/ledger_screen.dart';
import '../../features/pipeline/presentation/pipeline_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/vault/presentation/vault_screen.dart';
import 'lock_screen.dart';

/// Two stacked gates protect the app:
/// 1. **Auth** — `authStateProvider` must resolve to a signed-in user.
/// 2. **Biometric** — `unlockStateProvider` must be true (auto-unlocks on
///    web where biometric APIs aren't available).
///
/// Order matters: auth comes first because it's account-level (the user is
/// committing data to their cloud), biometric is device-level (right now).
/// Three tabs match the design bundle: Vault / Ledger / Pipeline.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      // Wait for the first auth emission so we don't bounce between routes
      // during the initial Firebase handshake.
      if (!ref.read(isAuthResolvedProvider)) return null;

      final user = ref.read(currentUserProvider);
      final unlocked = ref.read(unlockStateProvider);
      final loc = state.matchedLocation;

      if (user == null) {
        return loc == '/auth' ? null : '/auth';
      }
      if (loc == '/auth') return '/lock';
      if (!unlocked && loc != '/lock') return '/lock';
      if (unlocked && loc == '/lock') return '/vault';
      return null;
    },
    refreshListenable: _RouterListenable(ref),
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
      ShellRoute(
        builder: (context, state, child) => _RootShell(child: child),
        routes: [
          GoRoute(path: '/vault', builder: (_, __) => const VaultScreen()),
          GoRoute(path: '/ledger', builder: (_, __) => const LedgerScreen()),
          GoRoute(path: '/pipeline', builder: (_, __) => const PipelineScreen()),
        ],
      ),
      GoRoute(
        path: '/analytics',
        builder: (_, __) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
});

/// Wakes go_router whenever auth state OR unlock state changes.
class _RouterListenable extends ChangeNotifier {
  _RouterListenable(this._ref) {
    _ref.listen<bool>(unlockStateProvider, (_, __) => notifyListeners());
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

class _RootShell extends StatelessWidget {
  const _RootShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AmbientBackdrop(
      child: Stack(
        children: [
          Positioned.fill(child: child),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SafeArea(top: false, child: _LedgrTabBar()),
          ),
        ],
      ),
    );
  }
}

class _LedgrTabBar extends StatelessWidget {
  const _LedgrTabBar();

  static const _tabs = [
    _TabSpec(path: '/vault', label: 'Vault', icon: _BrandIcon.vault),
    _TabSpec(path: '/ledger', label: 'Ledger', icon: _BrandIcon.ledger),
    _TabSpec(path: '/pipeline', label: 'Pipeline', icon: _BrandIcon.pulse),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return LedgrGlassBar(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final t in _tabs)
              Expanded(
                child: _TabButton(
                  spec: t,
                  active: location.startsWith(t.path),
                  onTap: () => context.go(t.path),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? LedgrColors.lime : LedgrColors.textDim;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0x1AC9FF5E) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: active
              ? Border.all(color: const Color(0x4DC9FF5E), width: 0.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _renderIcon(spec.icon, color),
            const SizedBox(height: 3),
            Text(
              spec.label,
              style: LedgrType.sans(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderIcon(_BrandIcon icon, Color color) {
    switch (icon) {
      case _BrandIcon.vault:
        return LedgrIcons.vault(color: color, size: 20);
      case _BrandIcon.ledger:
        return LedgrIcons.ledger(color: color, size: 20);
      case _BrandIcon.pulse:
        return LedgrIcons.pulse(color: color, size: 20);
    }
  }
}

class _TabSpec {
  const _TabSpec({required this.path, required this.label, required this.icon});
  final String path;
  final String label;
  final _BrandIcon icon;
}

enum _BrandIcon { vault, ledger, pulse }
