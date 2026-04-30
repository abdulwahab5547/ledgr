import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../ledger/data/ledger_entry_model.dart';
import '../../ledger/data/ledger_repository.dart';
import '../../vault/data/account_repository.dart';
import '../../vault/data/adjustment_entry_model.dart';
import '../data/net_position_snapshot_model.dart';
import '../data/snapshot_repository.dart';

/// Captures and reconstructs `NetPositionSnapshot`s.
///
/// Two paths:
/// - [captureToday] writes a snapshot for today using **live** data (assets,
///   open lent, open borrowed, optional True Liquidity figure). Idempotent —
///   running it multiple times the same day overwrites the same key.
/// - [backfillFromHistory] walks the audit trail back to the earliest
///   adjustment and the earliest ledger entry, and writes one snapshot per
///   day in between for any day that doesn't already have one. Every account
///   balance for a given day is reconstructed from `AdjustmentEntry`'s
///   `balanceAfterMinorUnits` — that's the whole reason the audit log exists.
class SnapshotService {
  SnapshotService({
    required SnapshotRepository snapshots,
    required AccountRepository accounts,
    required LedgerRepository ledger,
    required Clock clock,
  })  : _snapshots = snapshots,
        _accounts = accounts,
        _ledger = ledger,
        _clock = clock;

  final SnapshotRepository _snapshots;
  final AccountRepository _accounts;
  final LedgerRepository _ledger;
  final Clock _clock;

  Future<void> captureToday({
    String currencyCode = 'PKR',
    int? trueLiquidityMinor,
  }) async {
    final now = _clock.now();
    final dateKey =
        NetPositionSnapshot.formatDateKey(DateTime(now.year, now.month, now.day));

    var assets = 0;
    for (final a in _accounts.listActive()) {
      if (a.currencyCode == currencyCode) assets += a.balanceMinorUnits;
    }

    var receivable = 0;
    var payable = 0;
    for (final e in _ledger.listAll()) {
      if (e.currencyCode != currencyCode) continue;
      if (e.settledAt != null) continue;
      if (e.isLent) {
        receivable += e.amountMinorUnits;
      } else {
        payable += e.amountMinorUnits;
      }
    }

    await _snapshots.put(
      NetPositionSnapshot(
        dateKey: dateKey,
        totalAssetsMinor: assets,
        netReceivableMinor: receivable,
        netPayableMinor: payable,
        currencyCode: currencyCode,
        takenAt: now,
        trueLiquidityMinor: trueLiquidityMinor,
      ),
    );
  }

  /// Reconstructs daily snapshots from history, skipping any day that
  /// already has one. Capped at [maxDays] to keep the operation bounded
  /// (default 365 — one year).
  ///
  /// Per-account balance for day `d` = `balanceAfterMinorUnits` of the
  /// latest `AdjustmentEntry` for that account with `occurredAt <= d 23:59`.
  /// If no adjustment exists by then, the account hasn't been opened yet
  /// and contributes 0.
  Future<int> backfillFromHistory({
    String currencyCode = 'PKR',
    int maxDays = 365,
  }) async {
    final accounts = _accounts.listAll();
    final adjustmentsByAccount = <String, List<AdjustmentEntry>>{};
    for (final a in accounts) {
      adjustmentsByAccount[a.id] = _accounts.historyFor(a.id)
        ..sort((x, y) => x.occurredAt.compareTo(y.occurredAt));
    }
    final ledgerEntries = _ledger.listAll();

    DateTime? earliest;
    void seed(DateTime d) {
      if (earliest == null || d.isBefore(earliest!)) earliest = d;
    }

    for (final list in adjustmentsByAccount.values) {
      if (list.isNotEmpty) seed(list.first.occurredAt);
    }
    for (final e in ledgerEntries) {
      seed(e.createdAt);
    }
    if (earliest == null) return 0;

    var day = DateTime(earliest!.year, earliest!.month, earliest!.day);
    final today = _clock.now();
    final endDay = DateTime(today.year, today.month, today.day);

    // Walk forward, but cap at maxDays so misconfigured anchors can't lock
    // up startup forever.
    var written = 0;
    var iterations = 0;
    while (!day.isAfter(endDay) && iterations <= maxDays) {
      iterations += 1;
      final key = NetPositionSnapshot.formatDateKey(day);
      if (!_snapshots.exists(key)) {
        final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

        var assets = 0;
        for (final a in accounts) {
          if (a.currencyCode != currencyCode) continue;
          final adjustments = adjustmentsByAccount[a.id]!;
          // Latest adjustment whose occurredAt <= dayEnd.
          AdjustmentEntry? latest;
          for (final adj in adjustments) {
            if (!adj.occurredAt.isAfter(dayEnd)) {
              latest = adj;
            } else {
              break;
            }
          }
          if (latest != null) assets += latest.balanceAfterMinorUnits;
        }

        var receivable = 0;
        var payable = 0;
        for (final e in ledgerEntries) {
          if (e.currencyCode != currencyCode) continue;
          if (e.createdAt.isAfter(dayEnd)) continue;
          // Settled before or at dayEnd? Then the entry is already cleared.
          if (e.settledAt != null && !e.settledAt!.isAfter(dayEnd)) continue;
          if (e.direction == LedgerDirection.lent) {
            receivable += e.amountMinorUnits;
          } else {
            payable += e.amountMinorUnits;
          }
        }

        await _snapshots.put(
          NetPositionSnapshot(
            dateKey: key,
            totalAssetsMinor: assets,
            netReceivableMinor: receivable,
            netPayableMinor: payable,
            currencyCode: currencyCode,
            takenAt: dayEnd,
          ),
        );
        written += 1;
      }
      day = day.add(const Duration(days: 1));
    }
    return written;
  }
}

final snapshotServiceProvider = Provider<SnapshotService>((ref) {
  return SnapshotService(
    snapshots: ref.watch(snapshotRepositoryProvider),
    accounts: ref.watch(accountRepositoryProvider),
    ledger: ref.watch(ledgerRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
});
