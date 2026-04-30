import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/charts/ledgr_donut.dart';
import '../../../core/design/charts/ledgr_flow_chart.dart';
import '../../../core/money/money.dart';
import '../../../core/time/clock.dart';
import '../data/expense_category.dart';
import '../data/incoming_payment_model.dart';
import '../data/incoming_payment_repository.dart';
import '../data/recurring_expense_model.dart';
import '../data/recurring_expense_repository.dart';
import 'recurrence_engine.dart';

/// User-selectable horizons for the Pipeline screen and the True Liquidity
/// formula. Default to 30d so the headline matches the SRD's True Liquidity
/// definition.
enum PipelineHorizon { d7, d14, d30, d90 }

extension PipelineHorizonX on PipelineHorizon {
  int get days => switch (this) {
        PipelineHorizon.d7 => 7,
        PipelineHorizon.d14 => 14,
        PipelineHorizon.d30 => 30,
        PipelineHorizon.d90 => 90,
      };
  String get label => '${days}d';
}

class PipelineHorizonNotifier extends Notifier<PipelineHorizon> {
  @override
  PipelineHorizon build() => PipelineHorizon.d30;

  void set(PipelineHorizon h) => state = h;
}

final pipelineHorizonProvider =
    NotifierProvider<PipelineHorizonNotifier, PipelineHorizon>(
  PipelineHorizonNotifier.new,
);

/// The active window driving every pipeline aggregation.
final pipelineWindowProvider = Provider<DateWindow>((ref) {
  final clock = ref.watch(clockProvider);
  final horizon = ref.watch(pipelineHorizonProvider);
  return DateWindow.fromDays(anchor: clock.now(), days: horizon.days);
});

/// Live stream of every open (not-yet-received) incoming payment.
final openIncomingProvider = StreamProvider<List<IncomingPayment>>((ref) {
  return ref.watch(incomingPaymentRepositoryProvider).watchOpen();
});

/// Live stream of every active recurring expense.
final activeRecurringProvider = StreamProvider<List<RecurringExpense>>((ref) {
  return ref.watch(recurringExpenseRepositoryProvider).watchActive();
});

/// All recurring occurrences (across all expenses) inside the active window.
final occurrencesInWindowProvider =
    Provider<List<RecurrenceOccurrence>>((ref) {
  final expenses = ref.watch(activeRecurringProvider).valueOrNull ?? const [];
  final window = ref.watch(pipelineWindowProvider);
  const engine = RecurrenceEngine();
  final out = <RecurrenceOccurrence>[];
  for (final e in expenses) {
    out.addAll(engine.expand(e, window));
  }
  out.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return out;
});

/// Sum of incoming payments expected within the window.
final incomingInWindowProvider = Provider<int>((ref) {
  final payments = ref.watch(openIncomingProvider).valueOrNull ?? const [];
  final window = ref.watch(pipelineWindowProvider);
  var total = 0;
  for (final p in payments) {
    if (window.contains(p.expectedDate)) total += p.amountMinorUnits;
  }
  return total;
});

/// Sum of recurring outflows occurring within the window.
final burnInWindowProvider = Provider<int>((ref) {
  final occurrences = ref.watch(occurrencesInWindowProvider);
  return occurrences.fold(0, (s, o) => s + o.amountMinorUnits);
});

/// Average monthly equivalent of every active recurring expense.
final monthlyBurnMinorProvider = Provider<int>((ref) {
  final expenses = ref.watch(activeRecurringProvider).valueOrNull ?? const [];
  return const RecurrenceEngine().monthlyEquivalentMinorUnits(expenses);
});

/// Per-day flow buckets that feed the line chart on the Pipeline screen.
final flowDaysProvider = Provider<List<FlowDay>>((ref) {
  final window = ref.watch(pipelineWindowProvider);
  final payments = ref.watch(openIncomingProvider).valueOrNull ?? const [];
  final occurrences = ref.watch(occurrencesInWindowProvider);
  return _bucketByDay(
    window: window,
    payments: payments,
    occurrences: occurrences,
  );
});

/// X-axis labels — first day, midpoint, last day. Mono caps in the chart.
final flowXLabelsProvider = Provider<Map<int, String>>((ref) {
  final days = ref.watch(flowDaysProvider);
  if (days.length < 2) return const {};
  final mid = days.length ~/ 2;
  return {
    0: days.first.label.toUpperCase(),
    mid: days[mid].label.toUpperCase(),
    days.length - 1: days.last.label.toUpperCase(),
  };
});

/// Monthly recurring spend, sliced by category, for the donut chart.
final categoryBreakdownProvider = Provider<List<DonutSegment>>((ref) {
  final expenses = ref.watch(activeRecurringProvider).valueOrNull ?? const [];
  final byCategory = <ExpenseCategory, int>{};
  for (final e in expenses) {
    final monthly = (e.amountMinorUnits * e.cadence.monthlyMultiplier).round();
    byCategory.update(e.category, (v) => v + monthly, ifAbsent: () => monthly);
  }
  if (byCategory.isEmpty) return const [];
  final entries = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final entry in entries)
      DonutSegment(
        label: entry.key.label,
        value: entry.value,
        color: entry.key.color,
      ),
  ];
});

/// Combined upcoming-events list (incoming + burn occurrences) sorted by
/// due date. Used by the lower card on the Pipeline screen.
class UpcomingItem {
  const UpcomingItem({
    required this.dueDate,
    required this.title,
    required this.amountMinorUnits,
    required this.kind,
    this.incomingId,
    this.recurringId,
  });

  final DateTime dueDate;
  final String title;

  /// Signed minor units: positive incoming, negative outgoing.
  final int amountMinorUnits;
  final UpcomingKind kind;

  final String? incomingId;
  final String? recurringId;
}

enum UpcomingKind { invoice, expense }

final upcomingItemsProvider = Provider<List<UpcomingItem>>((ref) {
  final window = ref.watch(pipelineWindowProvider);
  final payments = ref.watch(openIncomingProvider).valueOrNull ?? const [];
  final occurrences = ref.watch(occurrencesInWindowProvider);

  final items = <UpcomingItem>[
    for (final p in payments)
      if (window.contains(p.expectedDate))
        UpcomingItem(
          dueDate: p.expectedDate,
          title: p.label,
          amountMinorUnits: p.amountMinorUnits,
          kind: UpcomingKind.invoice,
          incomingId: p.id,
        ),
    for (final o in occurrences)
      UpcomingItem(
        dueDate: o.dueDate,
        title: o.expense.label,
        amountMinorUnits: -o.amountMinorUnits,
        kind: UpcomingKind.expense,
        recurringId: o.expense.id,
      ),
  ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return items;
});

/// A pure aggregation of incoming totals by currency. Used when reporting
/// surfaces want to be currency-aware (e.g. multi-currency handling later).
Money? primaryCurrencyTotal(List<IncomingPayment> payments) {
  if (payments.isEmpty) return null;
  final byCurrency = <String, int>{};
  for (final p in payments) {
    byCurrency.update(
      p.currencyCode,
      (v) => v + p.amountMinorUnits,
      ifAbsent: () => p.amountMinorUnits,
    );
  }
  final entry = byCurrency.entries.first;
  return Money(entry.value, currencyCode: entry.key);
}

// ─── helpers ───────────────────────────────────────────────────────────

List<FlowDay> _bucketByDay({
  required DateWindow window,
  required List<IncomingPayment> payments,
  required List<RecurrenceOccurrence> occurrences,
}) {
  final n = window.inclusiveDayCount;
  if (n <= 0) return const [];
  final buckets = List<_DayBucket>.generate(
    n,
    (i) => _DayBucket(window.from.add(Duration(days: i))),
  );
  for (final p in payments) {
    if (!window.contains(p.expectedDate)) continue;
    final idx = p.expectedDate
        .difference(window.from)
        .inDays
        .clamp(0, n - 1);
    buckets[idx].incoming += p.amountMinorUnits;
  }
  for (final o in occurrences) {
    final idx = o.dueDate.difference(window.from).inDays.clamp(0, n - 1);
    buckets[idx].outgoing += o.amountMinorUnits;
  }
  return [
    for (final b in buckets)
      FlowDay(
        label: _shortLabel(b.date),
        incoming: b.incoming,
        outgoing: b.outgoing,
      ),
  ];
}

class _DayBucket {
  _DayBucket(this.date);
  final DateTime date;
  int incoming = 0;
  int outgoing = 0;
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _shortLabel(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]}';
