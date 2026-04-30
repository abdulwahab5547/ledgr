import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:ledgr/core/storage/hive_bootstrap.dart';
import 'package:ledgr/core/time/clock.dart';
import 'package:ledgr/features/ledger/data/contact_model.dart';
import 'package:ledgr/features/ledger/data/contact_repository.dart';
import 'package:ledgr/features/ledger/data/ledger_entry_model.dart';
import 'package:ledgr/features/ledger/data/ledger_repository.dart';
import 'package:ledgr/features/pipeline/data/expense_category.dart';
import 'package:ledgr/features/pipeline/data/incoming_payment_model.dart';
import 'package:ledgr/features/pipeline/data/incoming_payment_repository.dart';
import 'package:ledgr/features/pipeline/data/recurring_expense_model.dart';
import 'package:ledgr/features/pipeline/data/recurring_expense_repository.dart';
import 'package:ledgr/features/ledger/domain/social_balances_provider.dart';
import 'package:ledgr/features/pipeline/domain/pipeline_providers.dart';
import 'package:ledgr/features/pipeline/domain/true_liquidity_provider.dart';
import 'package:ledgr/features/vault/data/account_model.dart';
import 'package:ledgr/features/vault/data/account_repository.dart';
import 'package:ledgr/features/vault/data/adjustment_entry_model.dart';
import 'package:ledgr/features/vault/domain/vault_providers.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

/// Verifies the True Liquidity formula end-to-end through the real Riverpod
/// graph: M2 vault aggregate, M3 social payables, M4 incoming + burn.
void main() {
  late Directory tmpDir;
  late ProviderContainer container;
  late _FixedClock clock;

  Future<void> registerAdapters() async {
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
  }

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('ledgr_tl_');
    Hive.init(tmpDir.path);
    await registerAdapters();
    final accounts = await Hive.openBox<Account>(HiveBoxes.accounts);
    final adjustments =
        await Hive.openBox<AdjustmentEntry>(HiveBoxes.adjustments);
    final contacts = await Hive.openBox<Contact>(HiveBoxes.contacts);
    final ledger = await Hive.openBox<LedgerEntry>(HiveBoxes.ledgerEntries);
    final incoming =
        await Hive.openBox<IncomingPayment>(HiveBoxes.incomingPayments);
    final recurring = await Hive.openBox<RecurringExpense>(
      HiveBoxes.recurringExpenses,
    );

    clock = _FixedClock(DateTime(2026, 4, 30, 12));
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        accountsBoxProvider.overrideWithValue(accounts),
        adjustmentsBoxProvider.overrideWithValue(adjustments),
        contactsBoxProvider.overrideWithValue(contacts),
        ledgerEntriesBoxProvider.overrideWithValue(ledger),
        incomingPaymentsBoxProvider.overrideWithValue(incoming),
        recurringExpensesBoxProvider.overrideWithValue(recurring),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await Hive.deleteFromDisk();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  Future<void> flushStreams() async {
    // Riverpod StreamProviders surface the first emit on a microtask. Wait
    // for every stream the formula reads from before computing.
    await container.read(accountsStreamProvider.future);
    await container.read(openIncomingProvider.future);
    await container.read(activeRecurringProvider.future);
    await container.read(openEntriesStreamProvider.future);
  }

  test('true liquidity formula is assets + incoming - payables - burn', () async {
    // Assets: Rs 5,00,000
    final accountRepo = container.read(accountRepositoryProvider);
    await accountRepo.create(
      label: 'Bank',
      type: AccountType.bank,
      openingBalanceMinorUnits: 50000000, // Rs 5,00,000
      currencyCode: 'PKR',
    );

    // Incoming: Rs 1,00,000 expected on May 5 (within 30d window).
    final incomingRepo = container.read(incomingPaymentRepositoryProvider);
    await incomingRepo.create(
      label: 'Acme Corp',
      amountMinorUnits: 10000000,
      currencyCode: 'PKR',
      expectedDate: DateTime(2026, 5, 5),
    );
    // Incoming: Rs 50,000 in 60 days — outside default 30d window.
    await incomingRepo.create(
      label: 'Far away',
      amountMinorUnits: 5000000,
      currencyCode: 'PKR',
      expectedDate: DateTime(2026, 6, 28),
    );

    // Payables: contact owes us nothing, we owe them Rs 4,800.
    final contactRepo = container.read(contactRepositoryProvider);
    final c = await contactRepo.create(name: 'Zara');
    final ledgerRepo = container.read(ledgerRepositoryProvider);
    await ledgerRepo.create(
      contactId: c.id,
      direction: LedgerDirection.borrowed,
      amountMinorUnits: 480000, // Rs 4,800
      currencyCode: 'PKR',
    );

    // Burn: monthly recurring Rs 18,500 anchored on May 4 → fires once
    // in the [Apr 30, May 30) window.
    final recurringRepo = container.read(recurringExpenseRepositoryProvider);
    await recurringRepo.create(
      label: 'Rent',
      amountMinorUnits: 1850000,
      currencyCode: 'PKR',
      cadence: Cadence.monthly,
      anchorDate: DateTime(2026, 5, 4),
      category: ExpenseCategory.rent,
    );

    // Default horizon is 30d. Window = [Apr 30, May 30).
    await flushStreams();
    final tl = container.read(trueLiquidityProvider);
    expect(tl.assets.minorUnits, 50000000);
    expect(tl.incoming.minorUnits, 10000000); // only the in-window one
    expect(tl.payables.minorUnits, 480000);
    expect(tl.burn.minorUnits, 1850000); // single Rent occurrence
    expect(
      tl.total.minorUnits,
      50000000 + 10000000 - 480000 - 1850000,
    );
    expect(tl.horizonDays, 30);
  });

  test('horizon switch changes the window inputs', () async {
    final accountRepo = container.read(accountRepositoryProvider);
    await accountRepo.create(
      label: 'Bank',
      type: AccountType.bank,
      openingBalanceMinorUnits: 0,
      currencyCode: 'PKR',
    );
    // Two incoming: one on day +5, one on day +60.
    final incomingRepo = container.read(incomingPaymentRepositoryProvider);
    await incomingRepo.create(
      label: 'Soon',
      amountMinorUnits: 1000,
      currencyCode: 'PKR',
      expectedDate: DateTime(2026, 5, 5),
    );
    await incomingRepo.create(
      label: 'Later',
      amountMinorUnits: 9000,
      currencyCode: 'PKR',
      expectedDate: DateTime(2026, 6, 29),
    );

    await flushStreams();
    container.read(pipelineHorizonProvider.notifier).set(PipelineHorizon.d7);
    expect(container.read(incomingInWindowProvider), 1000);

    container
        .read(pipelineHorizonProvider.notifier)
        .set(PipelineHorizon.d90);
    expect(container.read(incomingInWindowProvider), 10000);
  });

  test('runwayMonthsProvider divides assets by monthly burn', () async {
    final accountRepo = container.read(accountRepositoryProvider);
    await accountRepo.create(
      label: 'Bank',
      type: AccountType.bank,
      openingBalanceMinorUnits: 6000000, // Rs 60,000
      currencyCode: 'PKR',
    );
    final recurringRepo = container.read(recurringExpenseRepositoryProvider);
    await recurringRepo.create(
      label: 'Subs',
      amountMinorUnits: 1000000, // Rs 10,000 monthly
      currencyCode: 'PKR',
      cadence: Cadence.monthly,
      anchorDate: DateTime(2026, 5, 1),
      category: ExpenseCategory.subscriptions,
    );

    await flushStreams();
    expect(container.read(runwayMonthsProvider), 6);
  });

  test('runway is null when burn is zero', () async {
    final accountRepo = container.read(accountRepositoryProvider);
    await accountRepo.create(
      label: 'Bank',
      type: AccountType.bank,
      openingBalanceMinorUnits: 100000,
      currencyCode: 'PKR',
    );
    await flushStreams();
    expect(container.read(runwayMonthsProvider), isNull);
  });
}
