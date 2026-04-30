import 'package:flutter_test/flutter_test.dart';
import 'package:ledgr/features/ledger/data/contact_model.dart';
import 'package:ledgr/features/ledger/data/ledger_entry_model.dart';
import 'package:ledgr/features/ledger/domain/social_balances_provider.dart';

LedgerEntry _entry({
  required String contactId,
  required LedgerDirection dir,
  required int amount,
  String currencyCode = 'PKR',
  DateTime? settledAt,
}) {
  return LedgerEntry(
    id: '$contactId-${dir.name}-$amount-${settledAt ?? ''}',
    contactId: contactId,
    direction: dir,
    amountMinorUnits: amount,
    currencyCode: currencyCode,
    createdAt: DateTime(2026, 4, 30),
    settledAt: settledAt,
  );
}

Contact _contact(String id, String name) => Contact(
      id: id,
      name: name,
      createdAt: DateTime(2026, 4, 30),
    );

void main() {
  group('computeContactBalances', () {
    test('aggregates lent and borrowed per contact', () {
      final result = computeContactBalances(
        contacts: [
          _contact('1', 'Ayesha'),
          _contact('2', 'Bilal'),
        ],
        entries: [
          _entry(contactId: '1', dir: LedgerDirection.lent, amount: 18500),
          _entry(contactId: '1', dir: LedgerDirection.borrowed, amount: 4800),
          _entry(contactId: '2', dir: LedgerDirection.lent, amount: 6200),
        ],
      );
      expect(result['1']!.netSignedMinorUnits, 13700);
      expect(result['1']!.openLent, 18500);
      expect(result['1']!.openBorrowed, 4800);
      expect(result['2']!.netSignedMinorUnits, 6200);
    });

    test('drops contacts that have no entries', () {
      final result = computeContactBalances(
        contacts: [_contact('1', 'A'), _contact('2', 'B')],
        entries: [
          _entry(contactId: '1', dir: LedgerDirection.lent, amount: 100),
        ],
      );
      expect(result.keys, ['1']);
    });

    test('drops orphaned entries with missing contact', () {
      final result = computeContactBalances(
        contacts: [_contact('1', 'A')],
        entries: [
          _entry(contactId: '1', dir: LedgerDirection.lent, amount: 100),
          _entry(contactId: '999', dir: LedgerDirection.lent, amount: 200),
        ],
      );
      expect(result.keys, ['1']);
    });
  });

  group('SocialTotals.fromEntries', () {
    test('empty list returns zero totals', () {
      final t = SocialTotals.fromEntries(const []);
      expect(t.lent.minorUnits, 0);
      expect(t.borrowed.minorUnits, 0);
      expect(t.net.minorUnits, 0);
      expect(t.lentCount, 0);
      expect(t.borrowedCount, 0);
      expect(t.isEmpty, true);
    });

    test('aggregates within a single currency', () {
      final t = SocialTotals.fromEntries([
        _entry(contactId: 'a', dir: LedgerDirection.lent, amount: 18500),
        _entry(contactId: 'b', dir: LedgerDirection.lent, amount: 6200),
        _entry(contactId: 'c', dir: LedgerDirection.borrowed, amount: 4800),
      ]);
      expect(t.lent.minorUnits, 24700);
      expect(t.borrowed.minorUnits, 4800);
      expect(t.net.minorUnits, 19900);
      expect(t.lentCount, 2);
      expect(t.borrowedCount, 1);
    });
  });
}
