/// Future-scope interface for the SRD's "Automatic SMS Parsing" feature.
///
/// Implementations are platform-specific (Android only) and will read banking
/// alert SMS to derive a [SmsTransaction] suggestion. The app then routes
/// each suggestion through `AccountRepository.adjustBalance` so the audit
/// trail stays the single source of truth.
///
/// Nothing in the current build implements this. The interface lives here
/// so the eventual parser slots in cleanly.
abstract class SmsParser {
  /// Watches for new banking SMS and emits parsed transactions.
  Stream<SmsTransaction> watch();

  /// One-shot parse — used by tests and for backfilling an inbox.
  Future<List<SmsTransaction>> parseInbox();
}

class SmsTransaction {
  const SmsTransaction({
    required this.bankIdentifier,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.direction,
    required this.occurredAt,
    this.merchant,
    this.referenceId,
  });

  final String bankIdentifier;
  final int amountMinorUnits;
  final String currencyCode;
  final SmsDirection direction;
  final DateTime occurredAt;
  final String? merchant;
  final String? referenceId;
}

enum SmsDirection { credit, debit }
