import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/analytics/data/net_position_snapshot_model.dart';
import '../../features/ledger/data/contact_model.dart';
import '../../features/ledger/data/ledger_entry_model.dart';
import '../../features/pipeline/data/expense_category.dart';
import '../../features/pipeline/data/incoming_payment_model.dart';
import '../../features/pipeline/data/recurring_expense_model.dart';
import '../../features/settings/data/app_prefs_model.dart';
import '../../features/vault/data/account_model.dart';
import '../../features/vault/data/adjustment_entry_model.dart';
import '../security/encryption_key_service.dart';

/// Box names. Centralised so feature code never typos a name and adapters
/// are registered exactly once.
class HiveBoxes {
  const HiveBoxes._();
  static const accounts = 'accounts';
  static const adjustments = 'adjustments';
  // Reserved for later modules:
  static const contacts = 'contacts';
  static const ledgerEntries = 'ledger_entries';
  static const incomingPayments = 'incoming_payments';
  static const recurringExpenses = 'recurring_expenses';
  static const snapshots = 'net_position_snapshots';
  static const prefs = 'app_prefs';
}

/// Hive type IDs. Keep stable forever — changing one breaks existing data.
class HiveTypeIds {
  const HiveTypeIds._();
  static const account = 1;
  static const accountType = 2;
  static const adjustmentEntry = 3;
  static const adjustmentReason = 4;

  // Module 3 — Social Ledger
  static const contact = 10;
  static const ledgerEntry = 11;
  static const ledgerDirection = 12;

  // Module 4 — Pipeline & Burn
  static const incomingPayment = 20;
  static const recurringExpense = 21;
  static const cadence = 22;
  static const expenseCategory = 23;

  // Module 5 — Analytics, Export, Settings
  static const netPositionSnapshot = 30;
  static const appPrefs = 31;
}

/// One-time Hive setup: open Flutter integration, register every type
/// adapter, and open every encrypted box.
Future<void> initHive(EncryptionKeyService keyService) async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(HiveTypeIds.account)) {
    Hive.registerAdapter(AccountAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.accountType)) {
    Hive.registerAdapter(AccountTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.adjustmentEntry)) {
    Hive.registerAdapter(AdjustmentEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.adjustmentReason)) {
    Hive.registerAdapter(AdjustmentReasonAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.contact)) {
    Hive.registerAdapter(ContactAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.ledgerEntry)) {
    Hive.registerAdapter(LedgerEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.ledgerDirection)) {
    Hive.registerAdapter(LedgerDirectionAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.incomingPayment)) {
    Hive.registerAdapter(IncomingPaymentAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.recurringExpense)) {
    Hive.registerAdapter(RecurringExpenseAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.cadence)) {
    Hive.registerAdapter(CadenceAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.expenseCategory)) {
    Hive.registerAdapter(ExpenseCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.netPositionSnapshot)) {
    Hive.registerAdapter(NetPositionSnapshotAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.appPrefs)) {
    Hive.registerAdapter(AppPrefsAdapter());
  }

  // Web fallback: Web Crypto API is unavailable on plain-HTTP non-localhost
  // origins (e.g. http://192.168.x.x), which makes flutter_secure_storage —
  // and therefore the AES key — unreachable. The browser already sandboxes
  // IndexedDB per origin so encryption-at-rest doesn't add real protection
  // on web; skipping it here keeps the demo build runnable everywhere. On
  // iOS/Android the encrypted path stays.
  HiveAesCipher? cipher;
  if (!kIsWeb) {
    final keyBytes = await keyService.getOrCreateKey();
    cipher = HiveAesCipher(keyBytes);
  }

  await Future.wait([
    Hive.openBox<Account>(HiveBoxes.accounts, encryptionCipher: cipher),
    Hive.openBox<AdjustmentEntry>(
      HiveBoxes.adjustments,
      encryptionCipher: cipher,
    ),
    Hive.openBox<Contact>(HiveBoxes.contacts, encryptionCipher: cipher),
    Hive.openBox<LedgerEntry>(
      HiveBoxes.ledgerEntries,
      encryptionCipher: cipher,
    ),
    Hive.openBox<IncomingPayment>(
      HiveBoxes.incomingPayments,
      encryptionCipher: cipher,
    ),
    Hive.openBox<RecurringExpense>(
      HiveBoxes.recurringExpenses,
      encryptionCipher: cipher,
    ),
    Hive.openBox<NetPositionSnapshot>(
      HiveBoxes.snapshots,
      encryptionCipher: cipher,
    ),
    Hive.openBox<AppPrefs>(HiveBoxes.prefs, encryptionCipher: cipher),
  ]);
}

final encryptionKeyServiceProvider = Provider<EncryptionKeyService>(
  (ref) => EncryptionKeyService(),
);

/// Resolved at startup — see main.dart, which overrides this with the
/// already-opened boxes before runApp.
final accountsBoxProvider = Provider<Box<Account>>(
  (ref) => throw UnimplementedError('accountsBoxProvider must be overridden'),
);

final adjustmentsBoxProvider = Provider<Box<AdjustmentEntry>>(
  (ref) =>
      throw UnimplementedError('adjustmentsBoxProvider must be overridden'),
);

final contactsBoxProvider = Provider<Box<Contact>>(
  (ref) => throw UnimplementedError('contactsBoxProvider must be overridden'),
);

final ledgerEntriesBoxProvider = Provider<Box<LedgerEntry>>(
  (ref) => throw UnimplementedError(
    'ledgerEntriesBoxProvider must be overridden',
  ),
);

final incomingPaymentsBoxProvider = Provider<Box<IncomingPayment>>(
  (ref) => throw UnimplementedError(
    'incomingPaymentsBoxProvider must be overridden',
  ),
);

final recurringExpensesBoxProvider = Provider<Box<RecurringExpense>>(
  (ref) => throw UnimplementedError(
    'recurringExpensesBoxProvider must be overridden',
  ),
);

final snapshotsBoxProvider = Provider<Box<NetPositionSnapshot>>(
  (ref) =>
      throw UnimplementedError('snapshotsBoxProvider must be overridden'),
);

final prefsBoxProvider = Provider<Box<AppPrefs>>(
  (ref) => throw UnimplementedError('prefsBoxProvider must be overridden'),
);
