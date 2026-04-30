import 'package:intl/intl.dart';

/// Money is stored as integer minor units (cents/paise/etc) to eliminate
/// floating-point drift. Every persisted balance and amount in Ledgr flows
/// through this type at the boundary.
class Money implements Comparable<Money> {
  const Money(this.minorUnits, {this.currencyCode = 'USD'});

  /// Build [Money] from a major-unit double (e.g. dollars). Rounds to the
  /// nearest minor unit using banker's rounding semantics of [num.round].
  factory Money.fromMajor(num major, {String currencyCode = 'USD'}) {
    final minor = (major * 100).round();
    return Money(minor, currencyCode: currencyCode);
  }

  static const Money zero = Money(0);

  final int minorUnits;
  final String currencyCode;

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  double get major => minorUnits / 100.0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currencyCode: currencyCode);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currencyCode: currencyCode);
  }

  Money operator -() => Money(-minorUnits, currencyCode: currencyCode);

  bool operator >(Money other) {
    _assertSameCurrency(other);
    return minorUnits > other.minorUnits;
  }

  bool operator <(Money other) {
    _assertSameCurrency(other);
    return minorUnits < other.minorUnits;
  }

  bool operator >=(Money other) {
    _assertSameCurrency(other);
    return minorUnits >= other.minorUnits;
  }

  bool operator <=(Money other) {
    _assertSameCurrency(other);
    return minorUnits <= other.minorUnits;
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  /// Locale-aware formatting. UI boundary only — never persist formatted strings.
  String format({String? locale}) {
    final formatter = NumberFormat.simpleCurrency(
      locale: locale,
      name: currencyCode,
    );
    return formatter.format(major);
  }

  void _assertSameCurrency(Money other) {
    if (currencyCode != other.currencyCode) {
      throw ArgumentError(
        'Currency mismatch: $currencyCode vs ${other.currencyCode}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);

  @override
  String toString() => 'Money($minorUnits $currencyCode)';
}
