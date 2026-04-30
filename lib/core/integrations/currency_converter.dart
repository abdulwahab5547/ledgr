import '../money/money.dart';

/// Future-scope interface for the SRD's multi-currency support.
///
/// Concrete implementations will fetch exchange rates from an online source
/// or read from a cached snapshot. Until then, the app is single-currency
/// (PKR by default — overridable from Settings).
///
/// Convention: rates are quoted as "1 [from] = N [to]". Implementations are
/// expected to honour the user's primary currency by routing all conversions
/// through it (simplifies the multiplication path and minimises rounding).
abstract class CurrencyConverter {
  Future<double> rate({required String from, required String to});

  Future<Money> convert(Money amount, {required String to});
}
