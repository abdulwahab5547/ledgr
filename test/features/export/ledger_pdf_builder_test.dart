import 'package:flutter_test/flutter_test.dart';
import 'package:ledgr/features/export/ledger_pdf_builder.dart';
import 'package:ledgr/features/ledger/data/contact_model.dart';
import 'package:ledgr/features/ledger/data/ledger_entry_model.dart';
import 'package:ledgr/features/pipeline/data/expense_category.dart';
import 'package:ledgr/features/pipeline/data/incoming_payment_model.dart';
import 'package:ledgr/features/pipeline/data/recurring_expense_model.dart';
import 'package:ledgr/features/vault/data/account_model.dart';

void main() {
  late LedgerPdfBuilder builder;

  setUp(() {
    builder = const LedgerPdfBuilder();
  });

  test('produces a non-empty PDF starting with %PDF magic bytes', () async {
    final report = LedgerReport(
      month: 4,
      year: 2026,
      generatedAt: DateTime(2026, 5, 1, 10),
      accounts: [
        Account(
          id: '1',
          label: 'Bank',
          type: AccountType.bank,
          balanceMinorUnits: 50000000,
          currencyCode: 'PKR',
          createdAt: DateTime(2026, 4, 1),
          updatedAt: DateTime(2026, 4, 30),
        ),
      ],
      adjustments: const [],
      contacts: [
        Contact(
          id: 'c1',
          name: 'Ayesha',
          createdAt: DateTime(2026, 4, 1),
        ),
      ],
      ledgerEntries: [
        LedgerEntry(
          id: 'e1',
          contactId: 'c1',
          direction: LedgerDirection.lent,
          amountMinorUnits: 18500,
          currencyCode: 'PKR',
          createdAt: DateTime(2026, 4, 12),
        ),
      ],
      incoming: [
        IncomingPayment(
          id: 'p1',
          label: 'Acme Corp',
          amountMinorUnits: 45000000,
          currencyCode: 'PKR',
          expectedDate: DateTime(2026, 5, 3),
          createdAt: DateTime(2026, 4, 25),
        ),
      ],
      recurring: [
        RecurringExpense(
          id: 'r1',
          label: 'Rent',
          amountMinorUnits: 18500000,
          currencyCode: 'PKR',
          cadence: Cadence.monthly,
          anchorDate: DateTime(2026, 5, 1),
          category: ExpenseCategory.rent,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      snapshots: const [],
      trueLiquidityMinor: 47500000,
    );

    final bytes = await builder.build(report);
    expect(bytes.length, greaterThan(1000));
    // PDF spec: every file starts with "%PDF-".
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('survives an empty report', () async {
    final report = LedgerReport(
      month: 4,
      year: 2026,
      generatedAt: DateTime(2026, 5, 1, 10),
      accounts: const [],
      adjustments: const [],
      contacts: const [],
      ledgerEntries: const [],
      incoming: const [],
      recurring: const [],
      snapshots: const [],
      trueLiquidityMinor: 0,
    );
    final bytes = await builder.build(report);
    expect(bytes.length, greaterThan(500));
  });

  test('monthLabel formats as "April 2026"', () {
    final report = LedgerReport(
      month: 4,
      year: 2026,
      generatedAt: DateTime(2026, 5, 1),
      accounts: const [],
      adjustments: const [],
      contacts: const [],
      ledgerEntries: const [],
      incoming: const [],
      recurring: const [],
      snapshots: const [],
      trueLiquidityMinor: 0,
    );
    expect(report.monthLabel, 'April 2026');
  });
}
