import 'package:flutter_test/flutter_test.dart';
import 'package:ledgr/features/vault/data/account_model.dart';
import 'package:ledgr/features/vault/domain/vault_providers.dart';

Account _account({
  required int balanceMinorUnits,
  String currencyCode = 'USD',
  AccountType type = AccountType.bank,
  String label = 'Acc',
}) {
  return Account(
    id: 'id-${balanceMinorUnits}_$currencyCode',
    label: label,
    type: type,
    balanceMinorUnits: balanceMinorUnits,
    currencyCode: currencyCode,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  group('aggregateBalancesByCurrency', () {
    test('empty list returns empty map', () {
      expect(aggregateBalancesByCurrency(const []), isEmpty);
    });

    test('single currency sums correctly', () {
      final result = aggregateBalancesByCurrency([
        _account(balanceMinorUnits: 1000),
        _account(balanceMinorUnits: 2500),
        _account(balanceMinorUnits: 75),
      ]);
      expect(result.length, 1);
      expect(result['USD']!.minorUnits, 3575);
    });

    test('multi-currency keeps buckets separate', () {
      final result = aggregateBalancesByCurrency([
        _account(balanceMinorUnits: 1000, currencyCode: 'USD'),
        _account(balanceMinorUnits: 5000, currencyCode: 'EUR'),
        _account(balanceMinorUnits: 2000, currencyCode: 'USD'),
      ]);
      expect(result['USD']!.minorUnits, 3000);
      expect(result['EUR']!.minorUnits, 5000);
    });

    test('handles negative balances (overdraft)', () {
      final result = aggregateBalancesByCurrency([
        _account(balanceMinorUnits: 1000),
        _account(balanceMinorUnits: -300),
      ]);
      expect(result['USD']!.minorUnits, 700);
    });
  });
}
