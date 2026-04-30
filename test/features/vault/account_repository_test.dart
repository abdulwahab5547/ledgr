import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ledgr/core/storage/hive_bootstrap.dart';
import 'package:ledgr/core/time/clock.dart';
import 'package:ledgr/features/vault/data/account_model.dart';
import 'package:ledgr/features/vault/data/account_repository.dart';
import 'package:ledgr/features/vault/data/adjustment_entry_model.dart';

import '../../_helpers/cloud_test_helpers.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);
  DateTime _now;
  void advance(Duration d) => _now = _now.add(d);
  void setTo(DateTime when) => _now = when;
  @override
  DateTime now() => _now;
}

void main() {
  late Directory tmpDir;
  late Box<Account> accountsBox;
  late Box<AdjustmentEntry> adjustmentsBox;
  late AccountRepository repo;
  late _FixedClock clock;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('ledgr_test_');
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
    accountsBox = await Hive.openBox<Account>(HiveBoxes.accounts);
    adjustmentsBox = await Hive.openBox<AdjustmentEntry>(HiveBoxes.adjustments);
    clock = _FixedClock(DateTime(2026, 4, 30, 10));
    repo = AccountRepository(
      accounts: accountsCloudFor(accountsBox),
      adjustments: adjustmentsCloudFor(adjustmentsBox),
      clock: clock,
    );
  });

  tearDown(() async {
    await accountsBox.close();
    await adjustmentsBox.close();
    await Hive.deleteFromDisk();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  group('create', () {
    test('persists an account and seed audit entry for non-zero opening',
        () async {
      final account = await repo.create(
        label: 'Bank A',
        type: AccountType.bank,
        openingBalanceMinorUnits: 50000,
        currencyCode: 'USD',
      );
      expect(account.id, isNotEmpty);
      expect(repo.listActive(), [account]);

      final history = repo.historyFor(account.id);
      expect(history, hasLength(1));
      expect(history.single.reason, AdjustmentReason.initialBalance);
      expect(history.single.balanceAfterMinorUnits, 50000);
    });

    test('opening balance of zero writes no audit entry', () async {
      final account = await repo.create(
        label: 'Empty',
        type: AccountType.cash,
        openingBalanceMinorUnits: 0,
        currencyCode: 'USD',
      );
      expect(repo.historyFor(account.id), isEmpty);
    });
  });

  group('adjustBalance', () {
    test('applies delta and appends an audit entry', () async {
      final account = await repo.create(
        label: 'Bank A',
        type: AccountType.bank,
        openingBalanceMinorUnits: 10000,
        currencyCode: 'USD',
      );
      clock.advance(const Duration(hours: 1));

      final updated = await repo.adjustBalance(
        accountId: account.id,
        deltaMinorUnits: -2500,
        reason: AdjustmentReason.manual,
        note: 'Bought groceries',
      );
      expect(updated.balanceMinorUnits, 7500);

      final history = repo.historyFor(account.id);
      expect(history, hasLength(2));
      expect(history.first.deltaMinorUnits, -2500);
      expect(history.first.balanceAfterMinorUnits, 7500);
      expect(history.first.reason, AdjustmentReason.manual);
      expect(history.first.note, 'Bought groceries');
    });

    test('zero delta is a no-op', () async {
      final account = await repo.create(
        label: 'Bank A',
        type: AccountType.bank,
        openingBalanceMinorUnits: 1000,
        currencyCode: 'USD',
      );
      await repo.adjustBalance(
        accountId: account.id,
        deltaMinorUnits: 0,
        reason: AdjustmentReason.manual,
      );
      // Only the initial balance entry — no zero-delta noise.
      expect(repo.historyFor(account.id), hasLength(1));
    });

    test('throws on unknown account id', () async {
      expect(
        () => repo.adjustBalance(
          accountId: 'does-not-exist',
          deltaMinorUnits: 100,
          reason: AdjustmentReason.manual,
        ),
        throwsStateError,
      );
    });
  });

  group('setBalance (Quick Adjust)', () {
    test('computes delta to reach target and records it', () async {
      final account = await repo.create(
        label: 'Wallet',
        type: AccountType.wallet,
        openingBalanceMinorUnits: 1000,
        currencyCode: 'USD',
      );
      clock.advance(const Duration(minutes: 1));

      await repo.setBalance(
        accountId: account.id,
        newBalanceMinorUnits: 1750,
        note: 'Counted cash',
      );

      final fresh = repo.findById(account.id)!;
      expect(fresh.balanceMinorUnits, 1750);

      final last = repo.historyFor(account.id).first;
      expect(last.deltaMinorUnits, 750);
      expect(last.reason, AdjustmentReason.quickAdjust);
      expect(last.note, 'Counted cash');
    });

    test('setBalance to current value is a no-op', () async {
      final account = await repo.create(
        label: 'Wallet',
        type: AccountType.wallet,
        openingBalanceMinorUnits: 1000,
        currencyCode: 'USD',
      );
      await repo.setBalance(
        accountId: account.id,
        newBalanceMinorUnits: 1000,
      );
      expect(repo.historyFor(account.id), hasLength(1));
    });
  });

  group('archive / listActive', () {
    test('archived accounts are hidden from listActive', () async {
      final a = await repo.create(
        label: 'A',
        type: AccountType.bank,
        openingBalanceMinorUnits: 100,
        currencyCode: 'USD',
      );
      final b = await repo.create(
        label: 'B',
        type: AccountType.bank,
        openingBalanceMinorUnits: 200,
        currencyCode: 'USD',
      );
      await repo.archive(a.id);
      final active = repo.listActive();
      expect(active.map((x) => x.id), [b.id]);
      expect(repo.listAll(), hasLength(2));
    });

    test('listActive sorted alphabetically by label', () async {
      await repo.create(
        label: 'Charlie',
        type: AccountType.bank,
        openingBalanceMinorUnits: 0,
        currencyCode: 'USD',
      );
      await repo.create(
        label: 'alice',
        type: AccountType.bank,
        openingBalanceMinorUnits: 0,
        currencyCode: 'USD',
      );
      await repo.create(
        label: 'Bob',
        type: AccountType.bank,
        openingBalanceMinorUnits: 0,
        currencyCode: 'USD',
      );
      final labels =
          repo.listActive().map((a) => a.label.toLowerCase()).toList();
      expect(labels, ['alice', 'bob', 'charlie']);
    });
  });

  group('rename', () {
    test('updates label and updatedAt', () async {
      final account = await repo.create(
        label: 'Old',
        type: AccountType.bank,
        openingBalanceMinorUnits: 0,
        currencyCode: 'USD',
      );
      final originalUpdated = account.updatedAt;
      clock.advance(const Duration(minutes: 5));
      final renamed = await repo.rename(account.id, 'New');
      expect(renamed.label, 'New');
      expect(renamed.updatedAt.isAfter(originalUpdated), true);
    });
  });

  group('persistence', () {
    test('reopening the box yields the same accounts', () async {
      await repo.create(
        label: 'Persisted',
        type: AccountType.bank,
        openingBalanceMinorUnits: 4242,
        currencyCode: 'USD',
      );
      await accountsBox.close();
      await adjustmentsBox.close();
      final accountsBox2 = await Hive.openBox<Account>(HiveBoxes.accounts);
      final adjustmentsBox2 =
          await Hive.openBox<AdjustmentEntry>(HiveBoxes.adjustments);
      addTearDown(() async {
        await accountsBox2.close();
        await adjustmentsBox2.close();
      });
      final repo2 = AccountRepository(
        accounts: accountsCloudFor(accountsBox2),
        adjustments: adjustmentsCloudFor(adjustmentsBox2),
        clock: clock,
      );
      final accounts = repo2.listActive();
      expect(accounts, hasLength(1));
      expect(accounts.single.label, 'Persisted');
      expect(accounts.single.balanceMinorUnits, 4242);
    });
  });
}
