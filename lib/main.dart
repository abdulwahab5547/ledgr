import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/privacy/privacy_provider.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'core/security/biometric_gate.dart';
import 'core/security/encryption_key_service.dart';
import 'core/storage/hive_bootstrap.dart';
import 'core/sync/cloud_collection.dart';
import 'core/sync/sync_coordinator.dart';
import 'core/theme/app_theme.dart';
import 'features/vault/data/account_repository.dart';
import 'features/analytics/data/net_position_snapshot_model.dart';
import 'features/analytics/data/snapshot_repository.dart';
import 'features/analytics/domain/snapshot_service.dart';
import 'features/ledger/data/contact_model.dart';
import 'features/ledger/data/contact_repository.dart';
import 'features/ledger/data/ledger_entry_model.dart';
import 'features/ledger/data/ledger_repository.dart';
import 'features/pipeline/data/incoming_payment_model.dart';
import 'features/pipeline/data/incoming_payment_repository.dart';
import 'features/pipeline/data/recurring_expense_model.dart';
import 'features/pipeline/data/recurring_expense_repository.dart';
import 'features/pipeline/domain/true_liquidity_provider.dart';
import 'features/settings/data/app_prefs_model.dart';
import 'features/settings/data/prefs_repository.dart';
import 'features/vault/data/account_model.dart';
import 'features/vault/data/adjustment_entry_model.dart';

Future<void> _initFirebaseWithRetry() async {
  const attempts = 6;
  for (var i = 0; i < attempts; i++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return;
    } catch (e) {
      if (i == attempts - 1) {
        debugPrint('Firebase init failed after $attempts attempts: $e');
        return;
      }
      // 200ms, 400ms, 600ms, ... — gives the JS plugin registrant time.
      await Future<void>.delayed(Duration(milliseconds: 200 * (i + 1)));
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlay);

  // Best-effort Firebase init. Failure here mustn't kill the app — the auth
  // gate falls back to "anyone can use the app locally" so existing users
  // don't get locked out by a misconfigured project.
  //
  // On web, the firebase_core_web plugin uses a Pigeon channel that's
  // registered when the plugin's JS entry point loads. There's a known race
  // where Dart calls initializeApp before the channel handler attaches,
  // raising "Unable to establish connection on channel". Retry a few times
  // with backoff to give the plugin a chance to register.
  await _initFirebaseWithRetry();

  final keyService = EncryptionKeyService();
  try {
    await initHive(keyService);
  } catch (e, st) {
    runApp(_StartupError(error: e, stack: st));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        encryptionKeyServiceProvider.overrideWithValue(keyService),
        accountsBoxProvider
            .overrideWithValue(Hive.box<Account>(HiveBoxes.accounts)),
        adjustmentsBoxProvider.overrideWithValue(
          Hive.box<AdjustmentEntry>(HiveBoxes.adjustments),
        ),
        contactsBoxProvider
            .overrideWithValue(Hive.box<Contact>(HiveBoxes.contacts)),
        ledgerEntriesBoxProvider.overrideWithValue(
          Hive.box<LedgerEntry>(HiveBoxes.ledgerEntries),
        ),
        incomingPaymentsBoxProvider.overrideWithValue(
          Hive.box<IncomingPayment>(HiveBoxes.incomingPayments),
        ),
        recurringExpensesBoxProvider.overrideWithValue(
          Hive.box<RecurringExpense>(HiveBoxes.recurringExpenses),
        ),
        snapshotsBoxProvider.overrideWithValue(
          Hive.box<NetPositionSnapshot>(HiveBoxes.snapshots),
        ),
        prefsBoxProvider
            .overrideWithValue(Hive.box<AppPrefs>(HiveBoxes.prefs)),
        cloudCollectionsProvider.overrideWith((ref) {
          // Every CloudCollection in the app gets registered here so the
          // SyncCoordinator binds them to the active user on sign-in.
          return [
            ref.watch(accountsCloudProvider) as CloudCollection<Object?>,
            ref.watch(adjustmentsCloudProvider) as CloudCollection<Object?>,
            ref.watch(contactsCloudProvider) as CloudCollection<Object?>,
            ref.watch(ledgerEntriesCloudProvider) as CloudCollection<Object?>,
            ref.watch(incomingPaymentsCloudProvider)
                as CloudCollection<Object?>,
            ref.watch(recurringExpensesCloudProvider)
                as CloudCollection<Object?>,
            ref.watch(snapshotsCloudProvider) as CloudCollection<Object?>,
            ref.watch(prefsCloudProvider) as CloudCollection<Object?>,
          ];
        }),
      ],
      child: const LedgrApp(),
    ),
  );
}

class LedgrApp extends ConsumerStatefulWidget {
  const LedgrApp({super.key});

  @override
  ConsumerState<LedgrApp> createState() => _LedgrAppState();
}

class _LedgrAppState extends ConsumerState<LedgrApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onLaunch());
  }

  /// Daily snapshot capture + backfill of any missing days, plus applying
  /// the user's privacy-default preference. All best-effort; failures here
  /// must not block app start.
  Future<void> _onLaunch() async {
    // Activate the cloud-sync coordinator. It listens to authStateProvider
    // and binds every registered CloudCollection to the signed-in user.
    ref.read(syncBootstrapProvider);
    try {
      final prefs = ref.read(prefsRepositoryProvider).read();
      if (prefs.privacyDefaultOn) {
        ref.read(privacyModeProvider.notifier).setMasked(true);
      }
      final snapshots = ref.read(snapshotServiceProvider);
      await snapshots.backfillFromHistory(currencyCode: prefs.primaryCurrency);
      final tl = ref.read(trueLiquidityProvider);
      await snapshots.captureToday(
        currencyCode: prefs.primaryCurrency,
        trueLiquidityMinor: tl.total.minorUnits,
      );
    } catch (_) {
      // Snapshot pipeline must never block app boot.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(unlockStateProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Ledgr',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

/// Visible fallback when the bootstrap (Hive init, secure storage, etc.)
/// fails before the app can mount. Better than the white screen of death:
/// surfaces the error to the user with a retry hint.
class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.stack});

  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0B0D),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Couldn\'t start Ledgr',
                  style: TextStyle(
                    color: Color(0xFFF4F4EC),
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$error',
                  style: const TextStyle(
                    color: Color(0xFFFF8A6E),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$stack',
                  style: const TextStyle(
                    color: Color(0x9EF4F4EC),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
