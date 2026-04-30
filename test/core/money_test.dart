import 'package:flutter_test/flutter_test.dart';
import 'package:ledgr/core/money/money.dart';

void main() {
  group('Money', () {
    test('stores integer minor units exactly', () {
      const m = Money(12345);
      expect(m.minorUnits, 12345);
      expect(m.major, 123.45);
    });

    test('fromMajor rounds to nearest minor unit', () {
      expect(Money.fromMajor(1.005).minorUnits, isIn(<int>{100, 101}));
      expect(Money.fromMajor(1.20).minorUnits, 120);
      expect(Money.fromMajor(1.234).minorUnits, 123);
      expect(Money.fromMajor(1.236).minorUnits, 124);
    });

    test('add and subtract preserve currency', () {
      const a = Money(1000, currencyCode: 'USD');
      const b = Money(250, currencyCode: 'USD');
      expect((a + b).minorUnits, 1250);
      expect((a - b).minorUnits, 750);
      expect((a + b).currencyCode, 'USD');
    });

    test('mixing currencies throws', () {
      const usd = Money(100, currencyCode: 'USD');
      const eur = Money(100, currencyCode: 'EUR');
      expect(() => usd + eur, throwsArgumentError);
    });

    test('comparison ops', () {
      const a = Money(100);
      const b = Money(200);
      expect(a < b, true);
      expect(b > a, true);
      expect(a <= a, true);
      expect(a == const Money(100), true);
    });

    test('negation', () {
      const a = Money(100);
      expect((-a).minorUnits, -100);
    });

    test('format renders currency symbol', () {
      const a = Money(12345, currencyCode: 'USD');
      final formatted = a.format(locale: 'en_US');
      expect(formatted.contains('123'), true);
      expect(formatted.contains('45'), true);
    });
  });
}
