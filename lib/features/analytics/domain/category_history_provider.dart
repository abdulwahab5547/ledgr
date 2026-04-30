import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../pipeline/data/expense_category.dart';
import '../../pipeline/data/recurring_expense_repository.dart';
import '../../pipeline/domain/recurrence_engine.dart';
import '../../vault/data/account_repository.dart';
import '../../vault/data/adjustment_entry_model.dart';

/// Total spent in a category over a chosen window. Combines:
/// - Recurring expense **occurrences** that fired inside the window
///   (assumed paid).
/// - One-off audit entries with a category-tagged note (future scope —
///   currently no UI to assign categories to manual outflows, so this
///   contributes nothing yet).
class CategoryTotal {
  const CategoryTotal({required this.category, required this.minorUnits});
  final ExpenseCategory category;
  final int minorUnits;
}

/// 30 days of historical spend by category. The window ends at the current
/// clock and walks back 30 days.
final categoryHistory30dProvider = Provider<List<CategoryTotal>>((ref) {
  final clock = ref.watch(clockProvider);
  final expenses =
      ref.watch(recurringExpenseRepositoryProvider).listAll();
  final accountsRepo = ref.watch(accountRepositoryProvider);

  final today = clock.now();
  final from = DateTime(today.year, today.month, today.day - 30);
  final to = DateTime(today.year, today.month, today.day + 1);
  final window = DateWindow(from: from, to: to);

  final byCategory = <ExpenseCategory, int>{};

  // Recurring occurrences inside the window.
  const engine = RecurrenceEngine();
  for (final e in expenses) {
    for (final occ in engine.expand(e, window)) {
      byCategory.update(
        e.category,
        (v) => v + occ.amountMinorUnits,
        ifAbsent: () => occ.amountMinorUnits,
      );
    }
  }

  // Audit-trail outflows tagged with category cues. Today none of the app's
  // flows write a category onto an `AdjustmentEntry`; the hook is here so
  // the chart will gain richness once an enriched-adjustment workflow ships.
  for (final account in accountsRepo.listAll()) {
    for (final adj in accountsRepo.historyFor(account.id)) {
      if (adj.deltaMinorUnits >= 0) continue;
      if (adj.occurredAt.isBefore(from) || !adj.occurredAt.isBefore(to)) {
        continue;
      }
      // Skip: settlements and pipeline-received credits are inflows; manual
      // outflows fall through here. Tag every uncategorised manual outflow
      // as "Other" so the chart still reflects them.
      if (adj.reason == AdjustmentReason.manual ||
          adj.reason == AdjustmentReason.quickAdjust) {
        byCategory.update(
          ExpenseCategory.other,
          (v) => v + (-adj.deltaMinorUnits),
          ifAbsent: () => -adj.deltaMinorUnits,
        );
      }
    }
  }

  if (byCategory.isEmpty) return const [];
  final sorted = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in sorted)
      CategoryTotal(category: e.key, minorUnits: e.value),
  ];
});
