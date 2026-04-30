import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../vault/data/account_repository.dart';
import '../../vault/data/adjustment_entry_model.dart';
import '../data/incoming_payment_repository.dart';

/// Marks an [IncomingPayment] as received AND posts the offsetting credit
/// to a Vault account. Mirrors `SettlementService` so every balance change
/// in the app — Vault edit, ledger settlement, incoming received — flows
/// through `AccountRepository.adjustBalance` and the audit trail stays the
/// single source of truth.
///
/// On failure of the vault adjustment the receive flag is rolled back, so
/// the payment never sits in a half-received state.
class IncomingReceivedService {
  IncomingReceivedService({
    required IncomingPaymentRepository incoming,
    required AccountRepository accounts,
    required Clock clock,
  })  : _incoming = incoming,
        _accounts = accounts,
        _clock = clock;

  final IncomingPaymentRepository _incoming;
  final AccountRepository _accounts;
  final Clock _clock;

  Future<void> markReceived({
    required String paymentId,
    required String accountId,
    String? note,
  }) async {
    final payment = _incoming.findById(paymentId);
    if (payment == null) {
      throw StateError('IncomingPayment $paymentId not found');
    }
    if (!payment.isOpen) {
      throw StateError('IncomingPayment $paymentId is already received');
    }
    final account = _accounts.findById(accountId);
    if (account == null) {
      throw StateError('Account $accountId not found');
    }
    if (account.currencyCode != payment.currencyCode) {
      throw StateError(
        'Currency mismatch: account=${account.currencyCode}, '
        'payment=${payment.currencyCode}',
      );
    }

    final now = _clock.now();
    await _incoming.markReceived(
      id: paymentId,
      when: now,
      linkedAccountId: accountId,
    );

    try {
      await _accounts.adjustBalance(
        accountId: accountId,
        deltaMinorUnits: payment.amountMinorUnits,
        reason: AdjustmentReason.pipelineReceived,
        note: note ?? payment.label,
        linkedEntityId: paymentId,
      );
    } catch (_) {
      await _incoming.revertReceived(paymentId);
      rethrow;
    }
  }
}

final incomingReceivedServiceProvider =
    Provider<IncomingReceivedService>((ref) {
  return IncomingReceivedService(
    incoming: ref.watch(incomingPaymentRepositoryProvider),
    accounts: ref.watch(accountRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
});
