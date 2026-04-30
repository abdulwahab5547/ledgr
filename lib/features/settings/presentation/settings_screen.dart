import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/ambient_backdrop.dart';
import '../../../core/design/components/ledgr_back_header.dart';
import '../../../core/design/components/ledgr_buttons.dart';
import '../../../core/design/components/ledgr_card.dart';
import '../../../core/design/components/ledgr_text_field.dart';
import '../../../core/design/ledgr_colors.dart';
import '../../../core/design/ledgr_radii.dart';
import '../../../core/design/ledgr_typography.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/security/biometric_gate.dart';
import '../../../core/storage/hive_bootstrap.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/app_prefs_model.dart';
import '../data/prefs_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(appPrefsProvider);
    final prefs = prefsAsync.valueOrNull ?? AppPrefs();

    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            children: [
              const LedgrBackHeader(
                eyebrow: 'Settings',
                title: 'Preferences',
              ),
              const SizedBox(height: 20),
              const _AccountSection(),
              const SizedBox(height: 12),
              _SecuritySection(prefs: prefs),
              const SizedBox(height: 12),
              _PrivacySection(prefs: prefs),
              const SizedBox(height: 12),
              _CurrencySection(prefs: prefs),
              const SizedBox(height: 12),
              const _DangerZone(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection({required this.prefs});
  final AppPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsCard(
      eyebrow: 'SECURITY',
      child: _Toggle(
        title: 'Biometric on launch',
        subtitle:
            'Require Face ID, Touch ID, or device passcode every time the app opens.',
        value: prefs.requireBiometricOnLaunch,
        onChanged: (v) async {
          await ref.read(prefsRepositoryProvider).update(
                (p) => p.copyWith(requireBiometricOnLaunch: v),
              );
          await Haptics.tap();
        },
      ),
    );
  }
}

class _PrivacySection extends ConsumerWidget {
  const _PrivacySection({required this.prefs});
  final AppPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsCard(
      eyebrow: 'PRIVACY',
      child: _Toggle(
        title: 'Default to private',
        subtitle:
            'Start every session with monetary figures masked. The eye toggle on each screen flips it back.',
        value: prefs.privacyDefaultOn,
        onChanged: (v) async {
          await ref
              .read(prefsRepositoryProvider)
              .update((p) => p.copyWith(privacyDefaultOn: v));
          await Haptics.tap();
        },
      ),
    );
  }
}

class _CurrencySection extends ConsumerStatefulWidget {
  const _CurrencySection({required this.prefs});
  final AppPrefs prefs;

  @override
  ConsumerState<_CurrencySection> createState() => _CurrencySectionState();
}

class _CurrencySectionState extends ConsumerState<_CurrencySection> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.prefs.primaryCurrency);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      eyebrow: 'CURRENCY',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary currency',
            style: LedgrType.listTitle(),
          ),
          const SizedBox(height: 4),
          Text(
            'Used by every formatter and the True Liquidity formula. Three-letter ISO code.',
            style: LedgrType.sans(fontSize: 12, color: LedgrColors.textDim),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: LedgrTextField(
                  controller: _controller,
                  useMonoText: true,
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 10),
              LedgrPrimaryButton(
                label: 'Save',
                onPressed: () async {
                  final code = _controller.text.trim().toUpperCase();
                  if (code.length != 3) return;
                  await ref
                      .read(prefsRepositoryProvider)
                      .update((p) => p.copyWith(primaryCurrency: code));
                  await Haptics.success();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DangerZone extends ConsumerStatefulWidget {
  const _DangerZone();

  @override
  ConsumerState<_DangerZone> createState() => _DangerZoneState();
}

class _DangerZoneState extends ConsumerState<_DangerZone> {
  bool _busy = false;

  Future<void> _confirmWipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierColor: const Color(0xCC000000),
      builder: (_) => _WipeConfirmDialog(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final container = ProviderScope.containerOf(context);
    try {
      // Wipe every box that we manage.
      final boxes = [
        container.read(accountsBoxProvider),
        container.read(adjustmentsBoxProvider),
        container.read(contactsBoxProvider),
        container.read(ledgerEntriesBoxProvider),
        container.read(incomingPaymentsBoxProvider),
        container.read(recurringExpensesBoxProvider),
        container.read(snapshotsBoxProvider),
        container.read(prefsBoxProvider),
      ];
      for (final box in boxes) {
        await box.clear();
      }
      await container.read(encryptionKeyServiceProvider).destroyKey();
      // Force re-lock so the user has to re-authenticate; their data is gone.
      container.read(unlockStateProvider.notifier).lock();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      eyebrow: 'DANGER ZONE',
      tint: const Color(0x14FF8A6E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wipe all data',
            style: LedgrType.listTitle(color: LedgrColors.neg),
          ),
          const SizedBox(height: 4),
          Text(
            'Erases every account, ledger entry, pipeline item, and snapshot, '
            'and destroys the encryption key. This cannot be undone.',
            style: LedgrType.sans(fontSize: 12, color: LedgrColors.textDim),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _confirmWipe,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0x29FF8A6E),
                foregroundColor: LedgrColors.neg,
                disabledBackgroundColor: LedgrColors.hairline2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: LedgrColors.neg, width: 0.5),
                ),
              ),
              child: Text(
                _busy ? 'Wiping…' : 'Wipe data',
                style: LedgrType.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LedgrColors.neg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WipeConfirmDialog extends StatefulWidget {
  @override
  State<_WipeConfirmDialog> createState() => _WipeConfirmDialogState();
}

class _WipeConfirmDialogState extends State<_WipeConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF15161A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LedgrRadii.cardInner),
        side: const BorderSide(color: LedgrColors.hairline2, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wipe everything?',
              style: LedgrType.serif(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Type WIPE in caps to confirm. There is no recovery.',
              style: LedgrType.sans(
                fontSize: 13,
                color: LedgrColors.textDim,
              ),
            ),
            const SizedBox(height: 14),
            LedgrTextField(
              controller: _controller,
              hint: 'WIPE',
              useMonoText: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) =>
                  setState(() => _matches = v.trim() == 'WIPE'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: LedgrSecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _matches ? () => Navigator.of(context).pop(true) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: LedgrColors.neg,
                      foregroundColor: LedgrColors.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Confirm wipe',
                      style: LedgrType.sans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LedgrColors.bg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Account section — shows the signed-in email and exposes a sign-out
/// action that pops the user back to the auth screen via the router gate.
class _AccountSection extends ConsumerStatefulWidget {
  const _AccountSection();
  @override
  ConsumerState<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<_AccountSection> {
  bool _busy = false;

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signOut();
      // The router redirect picks up the auth state change and routes to /auth.
      ref.read(unlockStateProvider.notifier).lock();
      await Haptics.tap();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'Not signed in';
    return _SettingsCard(
      eyebrow: 'ACCOUNT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Signed in as', style: LedgrType.listTitle()),
          const SizedBox(height: 4),
          Text(
            email,
            style: LedgrType.mono(fontSize: 12.5, color: LedgrColors.textDim),
          ),
          const SizedBox(height: 14),
          LedgrSecondaryButton(
            label: _busy ? 'Signing out…' : 'Sign out',
            icon: Icons.logout_rounded,
            onPressed: _busy ? null : _signOut,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.eyebrow,
    required this.child,
    this.tint,
  });

  final String eyebrow;
  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return LedgrCard(
      padding: 18,
      gradient: tint == null
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tint!, tint!.withValues(alpha: 0.02)],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: LedgrType.eyebrow(letterSpacing: 1.2)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: LedgrType.listTitle()),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: LedgrType.sans(
                  fontSize: 12,
                  color: LedgrColors.textDim,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          activeThumbColor: LedgrColors.lime,
          activeTrackColor: const Color(0x33C9FF5E),
          inactiveTrackColor: LedgrColors.hairline2,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

