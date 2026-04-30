import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_bootstrap.dart';
import '../../../core/sync/cloud_collection.dart';
import '../../../core/time/clock.dart';
import 'account_model.dart';
import 'adjustment_entry_model.dart';

/// All read/write access to [Account] and the audit trail goes through here.
/// Balance changes ALWAYS produce a paired [AdjustmentEntry] — the audit log
/// is the source of truth for "how did this number get here". Module 3 (Ledger
/// settlement) and Module 4 (mark-as-received) call [adjustBalance] too,
/// so this single code path stays the only way balances move.
///
/// Writes go through [_accounts] (a [CloudCollection]) which mirrors them
/// to Firestore when the user is signed in. Reads still come from Hive so
/// the UI stays fast and works offline.
class AccountRepository {
  AccountRepository({
    required CloudCollection<Account> accounts,
    required CloudCollection<AdjustmentEntry> adjustments,
    required Clock clock,
    Uuid? uuid,
  })  : _accounts = accounts,
        _adjustments = adjustments,
        _clock = clock,
        _uuid = uuid ?? const Uuid();

  final CloudCollection<Account> _accounts;
  final CloudCollection<AdjustmentEntry> _adjustments;
  final Clock _clock;
  final Uuid _uuid;

  Box<Account> get _accountsBox => _accounts.box;
  Box<AdjustmentEntry> get _adjustmentsBox => _adjustments.box;

  List<Account> listActive() => _accountsBox.values
      .where((a) => !a.archived)
      .toList(growable: false)
    ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

  List<Account> listAll() => _accountsBox.values.toList(growable: false);

  Account? findById(String id) {
    for (final a in _accountsBox.values) {
      if (a.id == id) return a;
    }
    return null;
  }

  Stream<List<Account>> watchActive() async* {
    yield listActive();
    yield* _accountsBox.watch().map((_) => listActive());
  }

  Future<Account> create({
    required String label,
    required AccountType type,
    required int openingBalanceMinorUnits,
    required String currencyCode,
  }) async {
    final now = _clock.now();
    final account = Account(
      id: _uuid.v4(),
      label: label,
      type: type,
      balanceMinorUnits: openingBalanceMinorUnits,
      currencyCode: currencyCode,
      createdAt: now,
      updatedAt: now,
    );
    await _accounts.upsert(account);

    if (openingBalanceMinorUnits != 0) {
      await _writeAdjustment(
        accountId: account.id,
        delta: openingBalanceMinorUnits,
        balanceAfter: openingBalanceMinorUnits,
        reason: AdjustmentReason.initialBalance,
        note: 'Opening balance',
      );
    }
    return account;
  }

  Future<Account> rename(String id, String newLabel) async {
    final account = _requireAccount(id);
    account
      ..label = newLabel
      ..updatedAt = _clock.now();
    await _accounts.upsert(account);
    return account;
  }

  Future<Account> archive(String id) async {
    final account = _requireAccount(id);
    account
      ..archived = true
      ..updatedAt = _clock.now();
    await _accounts.upsert(account);
    return account;
  }

  /// Apply a delta (positive or negative) to an account. Persists the new
  /// balance AND writes an [AdjustmentEntry]. Both writes happen back-to-back;
  /// if the second fails the first is reverted to keep the audit log honest.
  Future<Account> adjustBalance({
    required String accountId,
    required int deltaMinorUnits,
    required AdjustmentReason reason,
    String? note,
    String? linkedEntityId,
  }) async {
    if (deltaMinorUnits == 0) return _requireAccount(accountId);
    final account = _requireAccount(accountId);
    final previous = account.balanceMinorUnits;
    final newBalance = previous + deltaMinorUnits;
    account
      ..balanceMinorUnits = newBalance
      ..updatedAt = _clock.now();
    await _accounts.upsert(account);
    try {
      await _writeAdjustment(
        accountId: accountId,
        delta: deltaMinorUnits,
        balanceAfter: newBalance,
        reason: reason,
        note: note,
        linkedEntityId: linkedEntityId,
      );
    } catch (_) {
      account
        ..balanceMinorUnits = previous
        ..updatedAt = _clock.now();
      await _accounts.upsert(account);
      rethrow;
    }
    return account;
  }

  /// "Quick Adjust" — set the balance to an exact figure. Computes the delta
  /// for the audit trail so the same single code path records it.
  Future<Account> setBalance({
    required String accountId,
    required int newBalanceMinorUnits,
    String? note,
  }) async {
    final account = _requireAccount(accountId);
    final delta = newBalanceMinorUnits - account.balanceMinorUnits;
    if (delta == 0) return account;
    return adjustBalance(
      accountId: accountId,
      deltaMinorUnits: delta,
      reason: AdjustmentReason.quickAdjust,
      note: note,
    );
  }

  List<AdjustmentEntry> historyFor(String accountId) {
    final entries = _adjustmentsBox.values
        .where((e) => e.accountId == accountId)
        .toList(growable: false)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return entries;
  }

  Future<void> _writeAdjustment({
    required String accountId,
    required int delta,
    required int balanceAfter,
    required AdjustmentReason reason,
    String? note,
    String? linkedEntityId,
  }) async {
    final entry = AdjustmentEntry(
      id: _uuid.v4(),
      accountId: accountId,
      deltaMinorUnits: delta,
      balanceAfterMinorUnits: balanceAfter,
      reason: reason,
      occurredAt: _clock.now(),
      note: note,
      linkedEntityId: linkedEntityId,
    );
    await _adjustments.upsert(entry);
  }

  Account _requireAccount(String id) {
    final account = _accountsBox.get(id);
    if (account == null) {
      throw StateError('Account $id not found');
    }
    return account;
  }
}

final accountsCloudProvider = Provider<CloudCollection<Account>>((ref) {
  return CloudCollection<Account>(
    collectionName: 'accounts',
    box: ref.watch(accountsBoxProvider),
    toJson: (a) => a.toJson(),
    fromJson: Account.fromJson,
    idOf: (a) => a.id,
  );
});

final adjustmentsCloudProvider =
    Provider<CloudCollection<AdjustmentEntry>>((ref) {
  return CloudCollection<AdjustmentEntry>(
    collectionName: 'adjustments',
    box: ref.watch(adjustmentsBoxProvider),
    toJson: (e) => e.toJson(),
    fromJson: AdjustmentEntry.fromJson,
    idOf: (e) => e.id,
  );
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    accounts: ref.watch(accountsCloudProvider),
    adjustments: ref.watch(adjustmentsCloudProvider),
    clock: ref.watch(clockProvider),
  );
});
