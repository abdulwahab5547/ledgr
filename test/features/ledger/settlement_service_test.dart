import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ledgr/core/storage/hive_bootstrap.dart';
import 'package:ledgr/core/time/clock.dart';
import 'package:ledgr/features/ledger/data/contact_model.dart';
import 'package:ledgr/features/ledger/data/contact_repository.dart';
import 'package:ledgr/features/ledger/data/ledger_entry_model.dart';
import 'package:ledgr/features/ledger/data/ledger_repository.dart';
import 'package:ledgr/features/ledger/domain/settlement_service.dart';
import 'package:ledgr/features/vault/data/account_model.dart';
import 'package:ledgr/features/vault/data/account_repository.dart';
import 'package:ledgr/features/vault/data/adjustment_entry_model.dart';

import '../../_helpers/cloud_test_helpers.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);
  DateTime _now;
  void advance(Duration d) => _now = _now.add(d);
  @override
  DateTime now() => _now;
}

void main() {
  late Directory tmpDir;
  late Box<Account> accountsBox;
  late Box<AdjustmentEntry> adjustmentsBox;
  late Box<Contact> contactsBox;
  late Box<LedgerEntry> entriesBox;
  late AccountRepository accounts;
  late ContactRepository contacts;
  late LedgerRepository ledger;
  late SettlementService settlement;
  late _FixedClock clock;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('ledgr_settle_');
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
    accountsBox = await Hive.openBox<Account>(HiveBoxes.accounts);
    adjustmentsBox = await Hive.openBox<AdjustmentEntry>(HiveBoxes.adjustments);
    contactsBox = await Hive.openBox<Contact>(HiveBoxes.contacts);
    entriesBox = await Hive.openBox<LedgerEntry>(HiveBoxes.ledgerEntries);
    clock = _FixedClock(DateTime(2026, 4, 30, 12));
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
    settlement = SettlementService(
      ledger: ledger,
      accounts: accounts,
      clock: clock,
    );
  });

  tearDown(() async {
    await accountsBox.close();
    await adjustmentsBox.close();
    await contactsBox.close();
    await entriesBox.close();
    await Hive.deleteFromDisk();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  group('settle (lent → account credited)', () {
    test('marks entry settled and increases account balance', () async {
      final account = await accounts.create(
        label: 'Meezan',
        type: AccountType.bank,
        openingBalanceMinorUnits: 100000,
        currencyCode: 'PKR',
      );
      final contact = await contacts.create(name: 'Ayesha');
      final entry = await ledger.create(
        contactId: contact.id,
        direction: LedgerDirection.lent,
        amountMinorUnits: 18500,
        currencyCode: 'PKR',
        note: 'Karachi trip',
      );

      clock.advance(const Duration(minutes: 5));
      await settlement.settle(
        entryId: entry.id,
        accountId: account.id,
      );

      final settledEntry = ledger.findById(entry.id)!;
      expect(settledEntry.settledAt, isNotNull);
      expect(settledEntry.linkedAccountId, account.id);

      final freshAccount = accounts.findById(account.id)!;
      expect(freshAccount.balanceMinorUnits, 100000 + 18500);

      // Audit row should exist with the right reason and link.
      final history = accounts.historyFor(account.id);
      final settlementRow = history.firstWhere(
        (a) => a.reason == AdjustmentReason.ledgerSettlement,
      );
      expect(settlementRow.deltaMinorUnits, 18500);
      expect(settlementRow.linkedEntityId, entry.id);
    });
  });

  group('settle (borrowed → account debited)', () {
    test('decreases account balance', () async {
      final account = await accounts.create(
        label: 'HBL',
        type: AccountType.bank,
        openingBalanceMinorUnits: 50000,
        currencyCode: 'PKR',
      );
      final contact = await contacts.create(name: 'Zara');
      final entry = await ledger.create(
        contactId: contact.id,
        direction: LedgerDirection.borrowed,
        amountMinorUnits: 4800,
        currencyCode: 'PKR',
      );

      clock.advance(const Duration(minutes: 5));
      await settlement.settle(
        entryId: entry.id,
        accountId: account.id,
      );

      final fresh = accounts.findById(account.id)!;
      expect(fresh.balanceMinorUnits, 50000 - 4800);
    });
  });

  group('error paths', () {
    test('rejects unknown entry id', () async {
      final account = await accounts.create(
        label: 'X',
        type: AccountType.cash,
        openingBalanceMinorUnits: 0,
        currencyCode: 'PKR',
      );
      expect(
        () => settlement.settle(
          entryId: 'nope',
          accountId: account.id,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects already-settled entry', () async {
      final account = await accounts.create(
        label: 'X',
        type: AccountType.cash,
        openingBalanceMinorUnits: 100000,
        currencyCode: 'PKR',
      );
      final contact = await contacts.create(name: 'Bilal');
      final entry = await ledger.create(
        contactId: contact.id,
        direction: LedgerDirection.lent,
        amountMinorUnits: 6200,
        currencyCode: 'PKR',
      );
      await settlement.settle(entryId: entry.id, accountId: account.id);
      await expectLater(
        settlement.settle(entryId: entry.id, accountId: account.id),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects currency mismatch', () async {
      final account = await accounts.create(
        label: 'USD',
        type: AccountType.cash,
        openingBalanceMinorUnits: 0,
        currencyCode: 'USD',
      );
      final contact = await contacts.create(name: 'Faisal');
      final entry = await ledger.create(
        contactId: contact.id,
        direction: LedgerDirection.lent,
        amountMinorUnits: 1000,
        currencyCode: 'PKR',
      );
      await expectLater(
        settlement.settle(entryId: entry.id, accountId: account.id),
        throwsA(isA<StateError>()),
      );
      // The entry must remain open after a rejected settle.
      expect(ledger.findById(entry.id)!.isOpen, true);
    });
  });
}
