import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../ledger/domain/social_balances_provider.dart';
import '../../vault/domain/vault_providers.dart';
import 'pipeline_providers.dart';

/// The headline metric. Mirrors the SRD's True Liquidity definition:
///
///   trueLiquidity = totalAssets + incomingInWindow
///                 − openSocialPayables − burnInWindow
///
/// Reuses providers from M2 (vaultTotalsByCurrency) and M3
/// (socialTotalsProvider.borrowed). When new sources of inflow/outflow are
/// added, they plug in here — every screen showing the headline reads from
/// this single provider.
class TrueLiquidity {
  const TrueLiquidity({
    required this.assets,
    required this.incoming,
    required this.payables,
    required this.burn,
    required this.currencyCode,
    required this.horizonDays,
  });

  final Money assets;
  final Money incoming;
  final Money payables;
  final Money burn;
  final String currencyCode;
  final int horizonDays;

  Money get total => Money(
        assets.minorUnits + incoming.minorUnits - payables.minorUnits - burn.minorUnits,
        currencyCode: currencyCode,
      );
}

final trueLiquidityProvider = Provider<TrueLiquidity>((ref) {
  final totals = ref.watch(vaultTotalsByCurrencyProvider);
  final social = ref.watch(socialTotalsProvider);
  final incoming = ref.watch(incomingInWindowProvider);
  final burn = ref.watch(burnInWindowProvider);
  final horizon = ref.watch(pipelineHorizonProvider);

  // Pick the primary currency: Vault total in PKR if present, else first
  // available, else fall back to PKR with zero assets.
  final assets = totals['PKR'] ??
      (totals.values.isEmpty ? null : totals.values.first);
  final currency = assets?.currencyCode ?? social.currencyCode;
  final assetsInPrimary = assets?.currencyCode == currency
      ? (assets ?? const Money(0, currencyCode: 'PKR'))
      : Money(0, currencyCode: currency);

  // Multi-currency social/incoming/burn aggregation lands with M5; for now
  // we trust the primary-currency assumption (PKR by default).
  final payables = social.currencyCode == currency
      ? social.borrowed
      : Money(0, currencyCode: currency);

  return TrueLiquidity(
    assets: assetsInPrimary,
    incoming: Money(incoming, currencyCode: currency),
    payables: payables,
    burn: Money(burn, currencyCode: currency),
    currencyCode: currency,
    horizonDays: horizon.days,
  );
});

/// Months of runway = liquid assets ÷ monthly burn (rounded down). When burn
/// is zero, returns null — the UI renders a dash in that case.
final runwayMonthsProvider = Provider<int?>((ref) {
  final totals = ref.watch(vaultTotalsByCurrencyProvider);
  final monthlyBurn = ref.watch(monthlyBurnMinorProvider);
  if (monthlyBurn <= 0) return null;
  final assets = totals['PKR'] ??
      (totals.values.isEmpty ? null : totals.values.first);
  final assetsMinor = assets?.minorUnits ?? 0;
  if (assetsMinor <= 0) return 0;
  return (assetsMinor / monthlyBurn).floor();
});
