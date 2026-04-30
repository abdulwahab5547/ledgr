import '../data/recurring_expense_model.dart';

/// One materialised firing of a [RecurringExpense]. Pure data; the
/// generator never persists these.
class RecurrenceOccurrence {
  const RecurrenceOccurrence({
    required this.expense,
    required this.dueDate,
  });
  final RecurringExpense expense;
  final DateTime dueDate;

  int get amountMinorUnits => expense.amountMinorUnits;
}

/// Date range in [from, to). Stored as midnight-aligned `DateTime`s.
class DateWindow {
  DateWindow({required DateTime from, required DateTime to})
      : from = _atMidnight(from),
        to = _atMidnight(to);

  factory DateWindow.fromDays({
    required DateTime anchor,
    required int days,
  }) {
    final start = _atMidnight(anchor);
    return DateWindow(from: start, to: start.add(Duration(days: days)));
  }

  final DateTime from;
  final DateTime to;

  bool contains(DateTime d) {
    final m = _atMidnight(d);
    return !m.isBefore(from) && m.isBefore(to);
  }

  int get inclusiveDayCount => to.difference(from).inDays;

  static DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Pure expansion of a recurring schedule into discrete occurrences inside a
/// window. The engine never mutates the source [RecurringExpense] and never
/// reads a clock — callers pass the window. Tests inject explicit windows.
///
/// Day-of-month semantics for monthly/yearly: the anchor's day-of-month is
/// preserved when possible; for shorter target months it clamps to the last
/// valid day (e.g. anchor on Jan 31 → Feb 28 in non-leap years, Feb 29 in
/// leap years, Apr 30, etc.). This matches how most banking systems treat
/// "monthly on the 31st" rules and avoids drift.
class RecurrenceEngine {
  const RecurrenceEngine();

  Iterable<RecurrenceOccurrence> expand(
    RecurringExpense expense,
    DateWindow window,
  ) sync* {
    if (!expense.active) return;
    final anchor = DateWindow._atMidnight(expense.anchorDate);
    if (window.from.isBefore(anchor) && window.to.isBefore(anchor)) {
      return;
    }
    var step = 0;
    while (true) {
      final due = _occurrenceAt(anchor, step, expense.cadence);
      if (!due.isBefore(window.to)) break;
      if (!due.isBefore(window.from)) {
        yield RecurrenceOccurrence(expense: expense, dueDate: due);
      }
      step += 1;
      if (step > _safetyLimit(expense.cadence, window)) break;
    }
  }

  /// Total minor units of every active recurring expense, expressed as a
  /// monthly equivalent (weekly × 52/12, monthly × 1, yearly × 1/12).
  int monthlyEquivalentMinorUnits(Iterable<RecurringExpense> active) {
    var sum = 0.0;
    for (final e in active) {
      if (!e.active) continue;
      sum += e.amountMinorUnits * e.cadence.monthlyMultiplier;
    }
    return sum.round();
  }

  // ─── internals ──────────────────────────────────────────────────────

  DateTime _occurrenceAt(DateTime anchor, int step, Cadence cadence) {
    switch (cadence) {
      case Cadence.weekly:
        return anchor.add(Duration(days: 7 * step));
      case Cadence.monthly:
        return _addMonths(anchor, step);
      case Cadence.yearly:
        return _addMonths(anchor, step * 12);
    }
  }

  /// Add `months` to `from`, clamping the day to the new month's last day if
  /// the original day-of-month doesn't exist there.
  DateTime _addMonths(DateTime from, int months) {
    final totalMonths = from.month - 1 + months;
    final newYear = from.year + (totalMonths ~/ 12);
    final newMonth = (totalMonths % 12) + 1;
    final lastDay = _daysInMonth(newYear, newMonth);
    final newDay = from.day > lastDay ? lastDay : from.day;
    return DateTime(newYear, newMonth, newDay);
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) return _isLeap(year) ? 29 : 28;
    const lengths = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return lengths[month];
  }

  bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);

  /// Hard upper bound on iterations to prevent runaway loops if an anchor
  /// date is unexpectedly far in the past.
  int _safetyLimit(Cadence cadence, DateWindow w) {
    switch (cadence) {
      case Cadence.weekly:
        return (w.inclusiveDayCount ~/ 7) + 64; // ~1y of headroom
      case Cadence.monthly:
        return (w.inclusiveDayCount ~/ 28) + 36; // ~3y of headroom
      case Cadence.yearly:
        return (w.inclusiveDayCount ~/ 365) + 12;
    }
  }
}
