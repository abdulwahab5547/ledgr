import 'package:flutter_test/flutter_test.dart';
import 'package:ledgr/features/pipeline/data/expense_category.dart';
import 'package:ledgr/features/pipeline/data/recurring_expense_model.dart';
import 'package:ledgr/features/pipeline/domain/recurrence_engine.dart';

RecurringExpense _expense({
  required String id,
  required Cadence cadence,
  required DateTime anchor,
  int amount = 100,
  bool active = true,
}) =>
    RecurringExpense(
      id: id,
      label: id,
      amountMinorUnits: amount,
      currencyCode: 'PKR',
      cadence: cadence,
      anchorDate: anchor,
      category: ExpenseCategory.other,
      createdAt: DateTime(2026),
      active: active,
    );

void main() {
  const engine = RecurrenceEngine();

  group('weekly', () {
    test('emits one occurrence per week starting at the anchor', () {
      final expense = _expense(
        id: 'gym',
        cadence: Cadence.weekly,
        anchor: DateTime(2026, 4, 1),
      );
      final window = DateWindow(
        from: DateTime(2026, 4, 1),
        to: DateTime(2026, 5, 1),
      );
      final dates = engine.expand(expense, window).map((o) => o.dueDate).toList();
      expect(dates, [
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 8),
        DateTime(2026, 4, 15),
        DateTime(2026, 4, 22),
        DateTime(2026, 4, 29),
      ]);
    });

    test('skips occurrences before the window start', () {
      final expense = _expense(
        id: 'g',
        cadence: Cadence.weekly,
        anchor: DateTime(2026, 1, 1),
      );
      final window = DateWindow(
        from: DateTime(2026, 4, 1),
        to: DateTime(2026, 4, 22),
      );
      final dates = engine.expand(expense, window).map((o) => o.dueDate).toList();
      // First occurrence inside window: 2026-04-02 (week 14 from Jan 1).
      expect(dates.first.isAfter(DateTime(2026, 3, 31)), true);
      expect(dates.last.isBefore(DateTime(2026, 4, 22)), true);
    });
  });

  group('monthly', () {
    test('preserves the anchor day-of-month when the target month has it', () {
      final expense = _expense(
        id: 'rent',
        cadence: Cadence.monthly,
        anchor: DateTime(2026, 1, 5),
      );
      final window = DateWindow(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 7, 1),
      );
      final dates = engine.expand(expense, window).map((o) => o.dueDate).toList();
      expect(dates, [
        DateTime(2026, 1, 5),
        DateTime(2026, 2, 5),
        DateTime(2026, 3, 5),
        DateTime(2026, 4, 5),
        DateTime(2026, 5, 5),
        DateTime(2026, 6, 5),
      ]);
    });

    test('clamps day-31 anchor into Feb (28 in non-leap, 29 in leap year)', () {
      final expense = _expense(
        id: 'salary',
        cadence: Cadence.monthly,
        anchor: DateTime(2027, 1, 31), // 2027 is non-leap
      );
      final w1 = DateWindow(
        from: DateTime(2027, 1, 31),
        to: DateTime(2027, 5, 1),
      );
      final dates = engine.expand(expense, w1).map((o) => o.dueDate).toList();
      expect(dates, [
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28), // clamped: 2027 is non-leap
        DateTime(2027, 3, 31),
        DateTime(2027, 4, 30), // April has only 30 days
      ]);

      final leapExpense = _expense(
        id: 'salary',
        cadence: Cadence.monthly,
        anchor: DateTime(2028, 1, 31), // 2028 IS a leap year
      );
      final w2 = DateWindow(
        from: DateTime(2028, 1, 31),
        to: DateTime(2028, 4, 1),
      );
      final leapDates =
          engine.expand(leapExpense, w2).map((o) => o.dueDate).toList();
      expect(leapDates[1], DateTime(2028, 2, 29));
    });

    test('does not lose precision over a long window', () {
      final expense = _expense(
        id: 'rent',
        cadence: Cadence.monthly,
        anchor: DateTime(2020, 1, 31),
      );
      final w = DateWindow(
        from: DateTime(2020, 1, 1),
        to: DateTime(2026, 1, 1),
      );
      final dates = engine.expand(expense, w).map((o) => o.dueDate).toList();
      // 6 years × 12 months = 72 occurrences.
      expect(dates.length, 72);
      // Anchor day-31 must always re-appear in months that have a 31st.
      final has31st = dates.where((d) => d.day == 31);
      expect(has31st, isNotEmpty);
    });
  });

  group('yearly', () {
    test('emits once per year on the anchor date', () {
      final expense = _expense(
        id: 'isp',
        cadence: Cadence.yearly,
        anchor: DateTime(2024, 4, 30),
      );
      final w = DateWindow(
        from: DateTime(2024, 1, 1),
        to: DateTime(2027, 1, 1),
      );
      final dates = engine.expand(expense, w).map((o) => o.dueDate).toList();
      expect(dates, [
        DateTime(2024, 4, 30),
        DateTime(2025, 4, 30),
        DateTime(2026, 4, 30),
      ]);
    });

    test('Feb 29 leap-year anchor clamps to Feb 28 in non-leap years', () {
      final expense = _expense(
        id: 'birthday',
        cadence: Cadence.yearly,
        anchor: DateTime(2024, 2, 29),
      );
      final w = DateWindow(
        from: DateTime(2024, 1, 1),
        to: DateTime(2029, 1, 1),
      );
      final dates = engine.expand(expense, w).map((o) => o.dueDate).toList();
      expect(dates, [
        DateTime(2024, 2, 29),
        DateTime(2025, 2, 28),
        DateTime(2026, 2, 28),
        DateTime(2027, 2, 28),
        DateTime(2028, 2, 29), // leap again
      ]);
    });
  });

  group('safety', () {
    test('inactive expense produces nothing', () {
      final expense = _expense(
        id: 'paused',
        cadence: Cadence.weekly,
        anchor: DateTime(2026, 4, 1),
        active: false,
      );
      expect(
        engine.expand(
          expense,
          DateWindow(
            from: DateTime(2026, 4, 1),
            to: DateTime(2026, 5, 1),
          ),
        ),
        isEmpty,
      );
    });

    test('window before anchor produces nothing', () {
      final expense = _expense(
        id: 'future',
        cadence: Cadence.monthly,
        anchor: DateTime(2030, 1, 1),
      );
      expect(
        engine
            .expand(
              expense,
              DateWindow(
                from: DateTime(2026, 1, 1),
                to: DateTime(2026, 6, 1),
              ),
            )
            .toList(),
        isEmpty,
      );
    });
  });

  group('monthlyEquivalentMinorUnits', () {
    test('weekly × 52/12, monthly × 1, yearly × 1/12', () {
      final exps = [
        _expense(
          id: 'a',
          cadence: Cadence.weekly,
          anchor: DateTime(2026, 1, 1),
          amount: 1200, // weekly Rs 12
        ),
        _expense(
          id: 'b',
          cadence: Cadence.monthly,
          anchor: DateTime(2026, 1, 1),
          amount: 50000, // monthly Rs 500
        ),
        _expense(
          id: 'c',
          cadence: Cadence.yearly,
          anchor: DateTime(2026, 1, 1),
          amount: 240000, // yearly Rs 2400
        ),
      ];
      final result = engine.monthlyEquivalentMinorUnits(exps);
      // 1200 * 52/12 + 50000 + 240000/12 = 5200 + 50000 + 20000 = 75200
      expect(result, 75200);
    });

    test('inactive entries are excluded', () {
      final exps = [
        _expense(
          id: 'paused',
          cadence: Cadence.monthly,
          anchor: DateTime(2026, 1, 1),
          amount: 99999,
          active: false,
        ),
      ];
      expect(engine.monthlyEquivalentMinorUnits(exps), 0);
    });
  });

  group('DateWindow', () {
    test('contains is half-open [from, to)', () {
      final w = DateWindow(
        from: DateTime(2026, 4, 1),
        to: DateTime(2026, 5, 1),
      );
      expect(w.contains(DateTime(2026, 4, 1)), true);
      expect(w.contains(DateTime(2026, 4, 30)), true);
      expect(w.contains(DateTime(2026, 5, 1)), false);
    });

    test('fromDays produces a [today, today+N) window', () {
      final w = DateWindow.fromDays(
        anchor: DateTime(2026, 4, 30, 14, 22),
        days: 7,
      );
      expect(w.from, DateTime(2026, 4, 30));
      expect(w.to, DateTime(2026, 5, 7));
      expect(w.inclusiveDayCount, 7);
    });
  });
}
