import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/time/clock.dart';
import '../analytics/data/snapshot_repository.dart';
import '../ledger/data/contact_repository.dart';
import '../ledger/data/ledger_repository.dart';
import '../pipeline/data/incoming_payment_repository.dart';
import '../pipeline/data/recurring_expense_repository.dart';
import '../pipeline/domain/true_liquidity_provider.dart';
import '../vault/data/account_repository.dart';
import 'ledger_pdf_builder.dart';

/// Glues live data sources to [LedgerPdfBuilder] and hands the resulting
/// bytes to the OS share/save UI via the `printing` package.
class PdfExportService {
  PdfExportService({
    required AccountRepository accounts,
    required ContactRepository contacts,
    required LedgerRepository ledger,
    required IncomingPaymentRepository incoming,
    required RecurringExpenseRepository recurring,
    required SnapshotRepository snapshots,
    required Clock clock,
    LedgerPdfBuilder builder = const LedgerPdfBuilder(),
  })  : _accounts = accounts,
        _contacts = contacts,
        _ledger = ledger,
        _incoming = incoming,
        _recurring = recurring,
        _snapshots = snapshots,
        _clock = clock,
        _builder = builder;

  final AccountRepository _accounts;
  final ContactRepository _contacts;
  final LedgerRepository _ledger;
  final IncomingPaymentRepository _incoming;
  final RecurringExpenseRepository _recurring;
  final SnapshotRepository _snapshots;
  final Clock _clock;
  final LedgerPdfBuilder _builder;

  /// Produces the bytes for the report covering [month]/[year]. Defaults to
  /// the current month from the clock.
  Future<Uint8List> buildBytes({
    int? month,
    int? year,
    int trueLiquidityMinor = 0,
  }) {
    final now = _clock.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    final report = LedgerReport(
      month: m,
      year: y,
      generatedAt: now,
      accounts: _accounts.listActive(),
      adjustments: const [],
      contacts: _contacts.listActive(),
      ledgerEntries: _ledger.listAll(),
      incoming: _incoming.listAll(),
      recurring: _recurring.listAll(),
      snapshots: _snapshots.listAll(),
      trueLiquidityMinor: trueLiquidityMinor,
    );
    return _builder.build(report);
  }

  /// Generates and pushes the PDF through the OS share sheet. Returns true
  /// when a destination accepted the file.
  Future<bool> exportAndShare({int trueLiquidityMinor = 0}) async {
    final bytes = await buildBytes(trueLiquidityMinor: trueLiquidityMinor);
    final filename =
        'Ledgr_${_clock.now().year}_${_clock.now().month.toString().padLeft(2, '0')}.pdf';
    return Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService(
    accounts: ref.watch(accountRepositoryProvider),
    contacts: ref.watch(contactRepositoryProvider),
    ledger: ref.watch(ledgerRepositoryProvider),
    incoming: ref.watch(incomingPaymentRepositoryProvider),
    recurring: ref.watch(recurringExpenseRepositoryProvider),
    snapshots: ref.watch(snapshotRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
});

/// Convenience read for screens — wraps the export call with the live True
/// Liquidity number so the cover page stays current.
final exportPdfActionProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final tl = ref.read(trueLiquidityProvider);
    return ref
        .read(pdfExportServiceProvider)
        .exportAndShare(trueLiquidityMinor: tl.total.minorUnits);
  };
});
