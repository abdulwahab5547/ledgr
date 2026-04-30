import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../data/account_model.dart';
import '../data/account_repository.dart';

/// Live stream of every active (non-archived) account. Backs the Vault list.
final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).watchActive();
});

/// The headline Vault number: total liquid assets across every active
/// account. Reused by Module 4's True Liquidity calculation — do not
/// re-compute totals elsewhere.
///
/// If accounts span currencies the result is a per-currency map. Module 5's
/// future-scope multi-currency conversion will collapse this to a single
/// reporting currency; for now we return it raw so callers can decide.
final vaultTotalsByCurrencyProvider = Provider<Map<String, Money>>((ref) {
  final asyncAccounts = ref.watch(accountsStreamProvider);
  return asyncAccounts.maybeWhen(
    data: aggregateBalancesByCurrency,
    orElse: () => const {},
  );
});

/// Single-currency convenience: when every active account uses the same
/// currency, returns that aggregate. If currencies differ, returns null —
/// callers should use [vaultTotalsByCurrencyProvider] and render a breakdown.
final vaultAggregateProvider = Provider<Money?>((ref) {
  final totals = ref.watch(vaultTotalsByCurrencyProvider);
  if (totals.length != 1) return null;
  return totals.values.single;
});

/// Pure function so it can be unit-tested without Riverpod.
Map<String, Money> aggregateBalancesByCurrency(List<Account> accounts) {
  final byCurrency = <String, int>{};
  for (final a in accounts) {
    byCurrency.update(
      a.currencyCode,
      (existing) => existing + a.balanceMinorUnits,
      ifAbsent: () => a.balanceMinorUnits,
    );
  }
  return {
    for (final entry in byCurrency.entries)
      entry.key: Money(entry.value, currencyCode: entry.key),
  };
}
