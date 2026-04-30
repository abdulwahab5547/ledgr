import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ledgr/core/storage/hive_bootstrap.dart';
import 'package:ledgr/core/time/clock.dart';
import 'package:ledgr/features/pipeline/data/incoming_payment_model.dart';
import 'package:ledgr/features/pipeline/data/incoming_payment_repository.dart';
import 'package:ledgr/features/pipeline/domain/incoming_received_service.dart';
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
  late Box<IncomingPayment> incomingBox;
  late AccountRepository accounts;
  late IncomingPaymentRepository incomingRepo;
  late IncomingReceivedService service;
  late _FixedClock clock;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('ledgr_received_');
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
    if (!Hive.isAdapterRegistered(HiveTypeIds.incomingPayment)) {
      Hive.registerAdapter(IncomingPaymentAdapter());
    }
    accountsBox = await Hive.openBox<Account>(HiveBoxes.accounts);
    adjustmentsBox = await Hive.openBox<AdjustmentEntry>(HiveBoxes.adjustments);
    incomingBox =
        await Hive.openBox<IncomingPayment>(HiveBoxes.incomingPayments);
    clock = _FixedClock(DateTime(2026, 4, 30, 12));
    accounts = AccountRepository(
      accounts: accountsCloudFor(accountsBox),
      adjustments: adjustmentsCloudFor(adjustmentsBox),
      clock: clock,
    );
    incomingRepo = IncomingPaymentRepository(
      payments: incomingPaymentsCloudFor(incomingBox),
      clock: clock,
    );
    service = IncomingReceivedService(
      incoming: incomingRepo,
      accounts: accounts,
      clock: clock,
    );
  });

  tearDown(() async {
    await accountsBox.close();
    await adjustmentsBox.close();
    await incomingBox.close();
    await Hive.deleteFromDisk();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test('marks payment received and credits account', () async {
    final account = await accounts.create(
      label: 'Bank',
      type: AccountType.bank,
      openingBalanceMinorUnits: 50000,
      currencyCode: 'PKR',
    );
    final payment = await incomingRepo.create(
      label: 'Acme Corp Invoice',
      amountMinorUnits: 12000,
      currencyCode: 'PKR',
      expectedDate: DateTime(2026, 5, 5),
    );
    clock.advance(const Duration(minutes: 5));

    await service.markReceived(
      paymentId: payment.id,
      accountId: account.id,
    );

    final fresh = incomingRepo.findById(payment.id)!;
    expect(fresh.receivedAt, isNotNull);
    expect(fresh.linkedAccountId, account.id);

    final freshAccount = accounts.findById(account.id)!;
    expect(freshAccount.balanceMinorUnits, 62000);

    final history = accounts.historyFor(account.id);
    final receipt = history.firstWhere(
      (a) => a.reason == AdjustmentReason.pipelineReceived,
    );
    expect(receipt.deltaMinorUnits, 12000);
    expect(receipt.linkedEntityId, payment.id);
  });

  test('rejects an already-received payment', () async {
    final account = await accounts.create(
      label: 'Bank',
      type: AccountType.bank,
      openingBalanceMinorUnits: 0,
      currencyCode: 'PKR',
    );
    final payment = await incomingRepo.create(
      label: 'Inv',
      amountMinorUnits: 1000,
      currencyCode: 'PKR',
      expectedDate: DateTime(2026, 5, 5),
    );
    await service.markReceived(
      paymentId: payment.id,
      accountId: account.id,
    );
    await expectLater(
      service.markReceived(paymentId: payment.id, accountId: account.id),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects currency mismatch and leaves payment open', () async {
    final usd = await accounts.create(
      label: 'USD',
      type: AccountType.bank,
      openingBalanceMinorUnits: 0,
      currencyCode: 'USD',
    );
    final payment = await incomingRepo.create(
      label: 'Inv',
      amountMinorUnits: 1000,
      currencyCode: 'PKR',
      expectedDate: DateTime(2026, 5, 5),
    );
    await expectLater(
      service.markReceived(paymentId: payment.id, accountId: usd.id),
      throwsA(isA<StateError>()),
    );
    expect(incomingRepo.findById(payment.id)!.isOpen, true);
  });
}
