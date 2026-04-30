import 'package:flutter_test/flutter_test.dart';
import 'package:ledgr/features/analytics/domain/allocation_provider.dart';
import 'package:ledgr/features/vault/data/account_model.dart';

Account _account({
  required String label,
  required int balance,
  AccountType type = AccountType.bank,
  bool archived = false,
}) =>
    Account(
      id: '$label-$balance',
      label: label,
      type: type,
      balanceMinorUnits: balance,
      currencyCode: 'PKR',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      archived: archived,
    );

void main() {
  group('computeAllocationSegments', () {
    test('drops zero / negative balances', () {
      final segs = computeAllocationSegments([
        _account(label: 'A', balance: 0),
        _account(label: 'B', balance: -500),
        _account(label: 'C', balance: 1000),
      ]);
      expect(segs.map((s) => s.label), ['C']);
    });

    test('sorted descending by value', () {
      final segs = computeAllocationSegments([
        _account(label: 'Small', balance: 100),
        _account(label: 'Big', balance: 50000),
        _account(label: 'Mid', balance: 1500),
      ]);
      expect(segs.map((s) => s.label), ['Big', 'Mid', 'Small']);
    });

    test('returns empty list when no positive balances', () {
      final segs = computeAllocationSegments([
        _account(label: 'A', balance: 0),
        _account(label: 'B', balance: 0),
      ]);
      expect(segs, isEmpty);
    });
  });
}
