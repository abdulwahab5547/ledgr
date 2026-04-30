import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/money/pkr_format.dart';
import '../analytics/data/net_position_snapshot_model.dart';
import '../ledger/data/contact_model.dart';
import '../ledger/data/ledger_entry_model.dart';
import '../pipeline/data/expense_category.dart';
import '../pipeline/data/incoming_payment_model.dart';
import '../pipeline/data/recurring_expense_model.dart';
import '../vault/data/account_model.dart';

/// Inputs for one monthly export. The builder is a pure function of these
/// — no providers, no database access — so tests can construct a Report
/// in-memory and assert on the resulting bytes.
class LedgerReport {
  const LedgerReport({
    required this.month,
    required this.year,
    required this.generatedAt,
    required this.accounts,
    required this.adjustments,
    required this.contacts,
    required this.ledgerEntries,
    required this.incoming,
    required this.recurring,
    required this.snapshots,
    required this.trueLiquidityMinor,
    this.currencyCode = 'PKR',
  });

  final int month;
  final int year;
  final DateTime generatedAt;
  final List<Account> accounts;
  final List<MapEntry<String, int>> adjustments; // (label, signed minor)
  final List<Contact> contacts;
  final List<LedgerEntry> ledgerEntries;
  final List<IncomingPayment> incoming;
  final List<RecurringExpense> recurring;
  final List<NetPositionSnapshot> snapshots;
  final int trueLiquidityMinor;
  final String currencyCode;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String get monthLabel => '${_months[month - 1]} $year';
}

/// Builds the monthly Ledgr summary as a PDF. Assembled with the `pdf`
/// package's primitives. Layout is light-on-white for printability — the
/// in-app dark theme doesn't translate to paper.
class LedgerPdfBuilder {
  const LedgerPdfBuilder();

  Future<Uint8List> build(LedgerReport report) async {
    final doc = pw.Document(
      title: 'Ledgr · ${report.monthLabel}',
      author: 'Ledgr',
      subject: 'Monthly financial summary',
    );

    // Use the PDF spec's built-in 14 standard fonts. Keeps the file small,
    // dependency-free, and avoids async font loading. The brand typography
    // doesn't translate to paper anyway — this is for printability.
    final serif = pw.Font.timesBold();
    final sansRegular = pw.Font.helvetica();
    final sansBold = pw.Font.helveticaBold();
    final mono = pw.Font.courier();

    final theme = pw.ThemeData.withFont(
      base: sansRegular,
      bold: sansBold,
    );

    pw.TextStyle eyebrow() => pw.TextStyle(
          font: sansBold,
          fontSize: 9,
          letterSpacing: 1.2,
          color: PdfColors.grey600,
        );
    pw.TextStyle body() => pw.TextStyle(font: sansRegular, fontSize: 11);
    pw.TextStyle amount() => pw.TextStyle(font: mono, fontSize: 11);
    pw.TextStyle amountBold() => pw.TextStyle(font: mono, fontSize: 14);

    pw.Widget section(String label, pw.Widget child) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(), style: eyebrow()),
            pw.SizedBox(height: 6),
            child,
          ],
        ),
      );
    }

    pw.TableRow tableRow(String left, String right, {bool bold = false}) {
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              left,
              style: bold ? pw.TextStyle(font: sansBold, fontSize: 11) : body(),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                right,
                style: bold
                    ? pw.TextStyle(font: mono, fontSize: 11.5)
                    : amount(),
              ),
            ),
          ),
        ],
      );
    }

    final totalAssets = report.accounts.fold<int>(
      0,
      (s, a) => s + (a.currencyCode == report.currencyCode
          ? a.balanceMinorUnits
          : 0),
    );
    final lentTotal = report.ledgerEntries
        .where((e) => e.isLent && e.isOpen)
        .fold<int>(0, (s, e) => s + e.amountMinorUnits);
    final borrowedTotal = report.ledgerEntries
        .where((e) => e.isBorrowed && e.isOpen)
        .fold<int>(0, (s, e) => s + e.amountMinorUnits);
    final pendingIncoming = report.incoming
        .where((p) => p.isOpen)
        .fold<int>(0, (s, p) => s + p.amountMinorUnits);

    // Recurring expense monthly burn.
    final monthlyBurn = report.recurring.fold<double>(
      0,
      (s, e) => s + e.amountMinorUnits * e.cadence.monthlyMultiplier,
    );

    // Category roll-up of the monthly burn.
    final byCategory = <ExpenseCategory, double>{};
    for (final e in report.recurring) {
      final monthly = e.amountMinorUnits * e.cadence.monthlyMultiplier;
      byCategory.update(
        e.category,
        (v) => v + monthly,
        ifAbsent: () => monthly,
      );
    }
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 48, 36, 48),
        build: (context) => [
          // Cover
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LEDGR', style: eyebrow()),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Monthly Summary',
                      style: pw.TextStyle(font: serif, fontSize: 36),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(report.monthLabel, style: body()),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'GENERATED',
                    style: eyebrow(),
                    textAlign: pw.TextAlign.right,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(_formatDate(report.generatedAt), style: body()),
                ],
              ),
            ],
          ),
          pw.Divider(height: 28, color: PdfColors.grey400),

          // Headline numbers
          pw.Row(
            children: [
              _bigNumber(
                'TRUE LIQUIDITY',
                PkrFormat.fromMinor(report.trueLiquidityMinor),
                serif,
                eyebrow(),
              ),
              _bigNumber(
                'LIQUID ASSETS',
                PkrFormat.fromMinor(totalAssets),
                serif,
                eyebrow(),
              ),
            ],
          ),

          // Vault accounts
          section(
            'Vault accounts',
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
              },
              children: [
                for (final a in report.accounts)
                  tableRow(
                    a.label,
                    PkrFormat.fromMinor(a.balanceMinorUnits),
                  ),
                tableRow(
                  'Total',
                  PkrFormat.fromMinor(totalAssets),
                  bold: true,
                ),
              ],
            ),
          ),

          // Social ledger
          section(
            'Social ledger',
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Open lent (receivable)',
                        style: body(),
                      ),
                    ),
                    pw.Text(
                      PkrFormat.fromMinor(lentTotal),
                      style: amount(),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Open borrowed (payable)',
                        style: body(),
                      ),
                    ),
                    pw.Text(
                      PkrFormat.fromMinor(borrowedTotal),
                      style: amount(),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Net',
                        style:
                            pw.TextStyle(font: sansBold, fontSize: 11),
                      ),
                    ),
                    pw.Text(
                      PkrFormat.fromMinor(lentTotal - borrowedTotal),
                      style: amountBold(),
                    ),
                  ],
                ),
                if (report.ledgerEntries.where((e) => e.isOpen).isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Open entries',
                    style: pw.TextStyle(font: sansBold, fontSize: 11),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Table(
                    columnWidths: const {
                      0: pw.FlexColumnWidth(3),
                      1: pw.FlexColumnWidth(1.4),
                      2: pw.FlexColumnWidth(2),
                    },
                    children: [
                      for (final e in report.ledgerEntries.where((x) => x.isOpen))
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                vertical: 3,
                              ),
                              child: pw.Text(
                                _contactName(report.contacts, e.contactId),
                                style: body(),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                vertical: 3,
                              ),
                              child: pw.Text(
                                e.isLent ? 'Lent' : 'Borrowed',
                                style: pw.TextStyle(
                                  font: sansBold,
                                  fontSize: 10,
                                  color: e.isLent
                                      ? PdfColors.green700
                                      : PdfColors.deepOrange700,
                                ),
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                PkrFormat.fromMinor(e.amountMinorUnits),
                                style: amount(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Pipeline
          section(
            'Pipeline & burn',
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('Pending incoming', style: body()),
                    ),
                    pw.Text(
                      PkrFormat.fromMinor(pendingIncoming),
                      style: amount(),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Recurring monthly burn',
                        style: body(),
                      ),
                    ),
                    pw.Text(
                      PkrFormat.fromMinor(monthlyBurn.round()),
                      style: amount(),
                    ),
                  ],
                ),
                if (sortedCategories.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Burn by category',
                    style: pw.TextStyle(font: sansBold, fontSize: 11),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Table(
                    columnWidths: const {
                      0: pw.FlexColumnWidth(3),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(2),
                    },
                    children: [
                      for (final entry in sortedCategories)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                vertical: 3,
                              ),
                              child: pw.Text(entry.key.label, style: body()),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                vertical: 3,
                              ),
                              child: pw.Text(
                                '${(entry.value / monthlyBurn * 100).round()}%',
                                style: amount(),
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                PkrFormat.fromMinor(entry.value.round()),
                                style: amount(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Footer
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'Generated locally · Ledgr',
              style: pw.TextStyle(
                font: sansRegular,
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String _formatDate(DateTime d) {
    final m = LedgerReport._months[d.month - 1];
    return '$m ${d.day}, ${d.year}';
  }

  static String _contactName(List<Contact> contacts, String id) {
    for (final c in contacts) {
      if (c.id == id) return c.name;
    }
    return '—';
  }

  static pw.Widget _bigNumber(
    String label,
    String value,
    pw.Font serif,
    pw.TextStyle eyebrow,
  ) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 12),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: eyebrow),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(font: serif, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}
