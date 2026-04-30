import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ledgr/core/storage/hive_bootstrap.dart';
import 'package:ledgr/core/time/clock.dart';
import 'package:ledgr/features/analytics/data/net_position_snapshot_model.dart';
import 'package:ledgr/features/analytics/data/snapshot_repository.dart';
import 'package:ledgr/features/analytics/domain/snapshot_service.dart';
import 'package:ledgr/features/ledger/data/contact_model.dart';
import 'package:ledgr/features/ledger/data/contact_repository.dart';
import 'package:ledgr/features/ledger/data/ledger_entry_model.dart';
import 'package:ledgr/features/ledger/data/ledger_repository.dart';
import 'package:ledgr/features/vault/data/account_model.dart';
import 'package:ledgr/features/vault/data/account_repository.dart';
import 'package:ledgr/features/vault/data/adjustment_entry_model.dart';

import '../../_helpers/cloud_test_helpers.dart';

class _MutableClock implements Clock {
  _MutableClock(this._now);
  DateTime _now;
  void setTo(DateTime when) => _now = when;
  @override
  DateTime now() => _now;
}

void main() {
  late Directory tmpDir;
  late Box<Account> accountsBox;
  late Box<AdjustmentEntry> adjustmentsBox;
  late Box<Contact> contactsBox;
  late Box<LedgerEntry> entriesBox;
  late Box<NetPositionSnapshot> snapshotsBox;
  late AccountRepository accounts;
  late ContactRepository contacts;
  late LedgerRepository ledger;
  late SnapshotRepository snapshots;
  late SnapshotService service;
  late _MutableClock clock;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('ledgr_snap_');
    Hive.init(tmpDir.path);
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
    if (!Hive.isAdapterRegistered(HiveTypeIds.netPositionSnapshot)) {
      Hive.registerAdapter(NetPositionSnapshotAdapter());
    }

    accountsBox = await Hive.openBox<Account>(HiveBoxes.accounts);
    adjustmentsBox = await Hive.openBox<AdjustmentEntry>(HiveBoxes.adjustments);
    contactsBox = await Hive.openBox<Contact>(HiveBoxes.contacts);
    entriesBox = await Hive.openBox<LedgerEntry>(HiveBoxes.ledgerEntries);
    snapshotsBox =
        await Hive.openBox<NetPositionSnapshot>(HiveBoxes.snapshots);

    clock = _MutableClock(DateTime(2026, 4, 30, 12));
    accounts = AccountRepository(
      accounts: accountsCloudFor(accountsBox),
      adjustments: adjustmentsCloudFor(adjustmentsBox),
      clock: clock,
    );
    contacts = ContactRepository(
      contacts: contactsCloudFor(contactsBox),
      clock: clock,
    );
    ledger = LedgerRepository(
      entries: ledgerEntriesCloudFor(entriesBox),
      clock: clock,
    );
    snapshots = SnapshotRepository(
      snapshots: snapshotsCloudFor(snapshotsBox),
    );
    service = SnapshotService(
      snapshots: snapshots,
      accounts: accounts,
      ledger: ledger,
      clock: clock,
    );
  });

  tearDown(() async {
    await accountsBox.close();
    await adjustmentsBox.close();
    await contactsBox.close();
    await entriesBox.close();
    await snapshotsBox.close();
    await Hive.deleteFromDisk();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  group('captureToday', () {
    test('writes today snapshot from live data', () async {
      await accounts.create(
        label: 'Bank',
        type: AccountType.bank,
        openingBalanceMinorUnits: 100000,
        currencyCode: 'PKR',
      );
      final c = await contacts.create(name: 'Ayesha');
      await ledger.create(
        contactId: c.id,
        direction: LedgerDirection.lent,
        amountMinorUnits: 5000,
        currencyCode: 'PKR',
      );
      await ledger.create(
        contactId: c.id,
        direction: LedgerDirection.borrowed,
        amountMinorUnits: 1500,
        currencyCode: 'PKR',
      );

      await service.captureToday(trueLiquidityMinor: 103500);

      final snap = snapshots.get('2026-04-30')!;
      expect(snap.totalAssetsMinor, 100000);
      expect(snap.netReceivableMinor, 5000);
      expect(snap.netPayableMinor, 1500);
      expect(snap.trueLiquidityMinor, 103500);
    });

    test('idempotent — calling twice the same day overwrites', () async {
      await accounts.create(
        label: 'Bank',
        type: AccountType.bank,
        openingBalanceMinorUnits: 1000,
        currencyCode: 'PKR',
      );
      await service.captureToday();
      // Mutate state, then capture again on the same day.
      await accounts.adjustBalance(
        accountId: accounts.listAll().single.id,
        deltaMinorUnits: 500,
        reason: AdjustmentReason.manual,
      );
      await service.captureToday();
      expect(snapshotsBox.length, 1);
      expect(snapshots.get('2026-04-30')!.totalAssetsMinor, 1500);
    });
  });

  group('backfillFromHistory', () {
    test('reconstructs daily totals from the audit trail', () async {
      // Day 1 (Apr 28): create account with opening Rs 1,000.
      clock.setTo(DateTime(2026, 4, 28, 9));
      final a = await accounts.create(
        label: 'Bank',
        type: AccountType.bank,
        openingBalanceMinorUnits: 100000,
        currencyCode: 'PKR',
      );

      // Day 2 (Apr 29): +500.
      clock.setTo(DateTime(2026, 4, 29, 9));
      await accounts.adjustBalance(
        accountId: a.id,
        deltaMinorUnits: 50000,
        reason: AdjustmentReason.manual,
      );

      // Day 3 (Apr 30) — today: -200.
      clock.setTo(DateTime(2026, 4, 30, 9));
      await accounts.adjustBalance(
        accountId: a.id,
        deltaMinorUnits: -20000,
        reason: AdjustmentReason.manual,
      );

      final written = await service.backfillFromHistory();
      // Apr 28, Apr 29, Apr 30 = 3 days.
      expect(written, 3);
      expect(snapshots.get('2026-04-28')!.totalAssetsMinor, 100000);
      expect(snapshots.get('2026-04-29')!.totalAssetsMinor, 150000);
      expect(snapshots.get('2026-04-30')!.totalAssetsMinor, 130000);
    });

    test('skips days that already have a snapshot', () async {
      clock.setTo(DateTime(2026, 4, 28, 9));
      await accounts.create(
        label: 'Bank',
        type: AccountType.bank,
        openingBalanceMinorUnits: 1000,
        currencyCode: 'PKR',
      );
      // Pre-seed Apr 29 manually with a different number.
      await snapshots.put(
        NetPositionSnapshot(
          dateKey: '2026-04-29',
          totalAssetsMinor: 999999,
          netReceivableMinor: 0,
          netPayableMinor: 0,
          currencyCode: 'PKR',
          takenAt: DateTime(2026, 4, 29, 23, 59, 59),
        ),
      );
      clock.setTo(DateTime(2026, 4, 30, 9));
      await service.backfillFromHistory();
      // The pre-seeded value must NOT be overwritten.
      expect(snapshots.get('2026-04-29')!.totalAssetsMinor, 999999);
      // But Apr 28 and Apr 30 should now exist.
      expect(snapshots.exists('2026-04-28'), true);
      expect(snapshots.exists('2026-04-30'), true);
    });

    test('walks open ledger entries by day', () async {
      clock.setTo(DateTime(2026, 4, 28, 9));
      final a = await accounts.create(
        label: 'Bank',
        type: AccountType.bank,
        openingBalanceMinorUnits: 0,
        currencyCode: 'PKR',
      );
      // Lend on Apr 28 — receivable should appear in snapshots from Apr 28.
      final c = await contacts.create(name: 'Bilal');
      await ledger.create(
        contactId: c.id,
        direction: LedgerDirection.lent,
        amountMinorUnits: 5000,
        currencyCode: 'PKR',
      );
      // Settle on Apr 30 — Apr 30 snapshot should show 0 receivable, but
      // Apr 28 / Apr 29 should still show 5000.
      clock.setTo(DateTime(2026, 4, 30, 14));
      await ledger.markSettled(
        entryId: ledger.listAll().single.id,
        when: DateTime(2026, 4, 30, 14),
        linkedAccountId: a.id,
      );

      await service.backfillFromHistory();
      expect(snapshots.get('2026-04-28')!.netReceivableMinor, 5000);
      expect(snapshots.get('2026-04-29')!.netReceivableMinor, 5000);
      expect(snapshots.get('2026-04-30')!.netReceivableMinor, 0);
    });

    test('does nothing when there is no history', () async {
      final written = await service.backfillFromHistory();
      expect(written, 0);
      expect(snapshotsBox.length, 0);
    });
  });
}
