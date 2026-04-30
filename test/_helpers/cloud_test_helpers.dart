import 'package:hive/hive.dart';
import 'package:ledgr/core/sync/cloud_collection.dart';
import 'package:ledgr/features/analytics/data/net_position_snapshot_model.dart';
import 'package:ledgr/features/ledger/data/contact_model.dart';
import 'package:ledgr/features/ledger/data/ledger_entry_model.dart';
import 'package:ledgr/features/pipeline/data/incoming_payment_model.dart';
import 'package:ledgr/features/pipeline/data/recurring_expense_model.dart';
import 'package:ledgr/features/settings/data/app_prefs_model.dart';
import 'package:ledgr/features/vault/data/account_model.dart';
import 'package:ledgr/features/vault/data/adjustment_entry_model.dart';

/// Shorthand factories so tests don't need to spell out the toJson/fromJson
/// closures every time. CloudCollection's lazy Firestore lookup means these
/// are safe to construct without initialising Firebase — as long as no test
/// calls bindToUser, no Firestore call ever happens.
CloudCollection<Account> accountsCloudFor(Box<Account> box) {
  return CloudCollection<Account>(
    collectionName: 'accounts',
    box: box,
    toJson: (a) => a.toJson(),
    fromJson: Account.fromJson,
    idOf: (a) => a.id,
  );
}

CloudCollection<AdjustmentEntry> adjustmentsCloudFor(
  Box<AdjustmentEntry> box,
) {
  return CloudCollection<AdjustmentEntry>(
    collectionName: 'adjustments',
    box: box,
    toJson: (e) => e.toJson(),
    fromJson: AdjustmentEntry.fromJson,
    idOf: (e) => e.id,
  );
}

CloudCollection<Contact> contactsCloudFor(Box<Contact> box) {
  return CloudCollection<Contact>(
    collectionName: 'contacts',
    box: box,
    toJson: (c) => c.toJson(),
    fromJson: Contact.fromJson,
    idOf: (c) => c.id,
  );
}

CloudCollection<LedgerEntry> ledgerEntriesCloudFor(Box<LedgerEntry> box) {
  return CloudCollection<LedgerEntry>(
    collectionName: 'ledger_entries',
    box: box,
    toJson: (e) => e.toJson(),
    fromJson: LedgerEntry.fromJson,
    idOf: (e) => e.id,
  );
}

CloudCollection<IncomingPayment> incomingPaymentsCloudFor(
  Box<IncomingPayment> box,
) {
  return CloudCollection<IncomingPayment>(
    collectionName: 'incoming_payments',
    box: box,
    toJson: (p) => p.toJson(),
    fromJson: IncomingPayment.fromJson,
    idOf: (p) => p.id,
  );
}

CloudCollection<RecurringExpense> recurringExpensesCloudFor(
  Box<RecurringExpense> box,
) {
  return CloudCollection<RecurringExpense>(
    collectionName: 'recurring_expenses',
    box: box,
    toJson: (e) => e.toJson(),
    fromJson: RecurringExpense.fromJson,
    idOf: (e) => e.id,
  );
}

CloudCollection<NetPositionSnapshot> snapshotsCloudFor(
  Box<NetPositionSnapshot> box,
) {
  return CloudCollection<NetPositionSnapshot>(
    collectionName: 'net_position_snapshots',
    box: box,
    toJson: (s) => s.toJson(),
    fromJson: NetPositionSnapshot.fromJson,
    idOf: (s) => s.dateKey,
  );
}

CloudCollection<AppPrefs> prefsCloudFor(Box<AppPrefs> box) {
  return CloudCollection<AppPrefs>(
    collectionName: 'app_prefs',
    box: box,
    toJson: (p) => p.toJson(),
    fromJson: AppPrefs.fromJson,
    idOf: (_) => AppPrefs.singletonKey,
  );
}
