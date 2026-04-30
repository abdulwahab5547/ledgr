import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../vault/data/account_repository.dart';
import '../../vault/data/adjustment_entry_model.dart';
import '../data/ledger_entry_model.dart';
import '../data/ledger_repository.dart';

/// Marks a [LedgerEntry] as settled AND posts the offsetting balance change
/// to a Vault account through [AccountRepository.adjustBalance]. Both writes
/// are paired: if the second fails, the first is reverted so the ledger
/// never sits in a half-settled state.
///
/// Direction semantics:
/// - LENT → user is receiving money → account balance INCREASES.
/// - BORROWED → user is paying back → account balance DECREASES.
class SettlementService {
  SettlementService({
    required LedgerRepository ledger,
    required AccountRepository accounts,
    required Clock clock,
  })  : _ledger = ledger,
        _accounts = accounts,
        _clock = clock;

  final LedgerRepository _ledger;
  final AccountRepository _accounts;
  final Clock _clock;

  Future<void> settle({
    required String entryId,
    required String accountId,
    String? note,
  }) async {
    final entry = _ledger.findById(entryId);
    if (entry == null) {
      throw StateError('LedgerEntry $entryId not found');
    }
    if (!entry.isOpen) {
      throw StateError('LedgerEntry $entryId is already settled');
    }
    final account = _accounts.findById(accountId);
    if (account == null) {
      throw StateError('Account $accountId not found');
    }
    if (account.currencyCode != entry.currencyCode) {
      throw StateError(
        'Currency mismatch: account=${account.currencyCode}, '
        'entry=${entry.currencyCode}',
      );
    }

    final delta = entry.signedMinorUnits;
    final now = _clock.now();

    // 1. Mark settled first so the entry's linkedAccountId is set when the
    //    AdjustmentEntry references it.
    await _ledger.markSettled(
      entryId: entryId,
      when: now,
      linkedAccountId: accountId,
    );

    try {
      await _accounts.adjustBalance(
        accountId: accountId,
        deltaMinorUnits: delta,
        reason: AdjustmentReason.ledgerSettlement,
        note: note ?? entry.note,
        linkedEntityId: entryId,
      );
    } catch (_) {
      // Rollback: keep the ledger consistent.
      await _ledger.revertSettlement(entryId);
      rethrow;
    }
  }
}

final settlementServiceProvider = Provider<SettlementService>((ref) {
  return SettlementService(
    ledger: ref.watch(ledgerRepositoryProvider),
    accounts: ref.watch(accountRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
});
