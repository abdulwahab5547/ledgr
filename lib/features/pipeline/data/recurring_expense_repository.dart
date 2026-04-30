import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_bootstrap.dart';
import '../../../core/sync/cloud_collection.dart';
import '../../../core/time/clock.dart';
import 'expense_category.dart';
import 'recurring_expense_model.dart';

class RecurringExpenseRepository {
  RecurringExpenseRepository({
    required CloudCollection<RecurringExpense> expenses,
    required Clock clock,
    Uuid? uuid,
  })  : _expenses = expenses,
        _clock = clock,
        _uuid = uuid ?? const Uuid();

  final CloudCollection<RecurringExpense> _expenses;
  final Clock _clock;
  final Uuid _uuid;

  Box<RecurringExpense> get _box => _expenses.box;

  List<RecurringExpense> listAll() => _box.values.toList(growable: false);

  List<RecurringExpense> listActive() {
    final out = _box.values.where((e) => e.active).toList()
      ..sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
    return out;
  }

  Stream<List<RecurringExpense>> watchActive() async* {
    yield listActive();
    yield* _box.watch().map((_) => listActive());
  }

  RecurringExpense? findById(String id) {
    for (final e in _box.values) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<RecurringExpense> create({
    required String label,
    required int amountMinorUnits,
    required String currencyCode,
    required Cadence cadence,
    required DateTime anchorDate,
    required ExpenseCategory category,
    String? linkedAccountId,
  }) async {
    if (amountMinorUnits <= 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'Must be positive',
      );
    }
    final e = RecurringExpense(
      id: _uuid.v4(),
      label: label,
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
      cadence: cadence,
      anchorDate: anchorDate,
      category: category,
      createdAt: _clock.now(),
      linkedAccountId: linkedAccountId,
    );
    await _expenses.upsert(e);
    return e;
  }

  Future<void> update(RecurringExpense expense) async {
    final existing = _require(expense.id);
    existing
      ..label = expense.label
      ..amountMinorUnits = expense.amountMinorUnits
      ..currencyCode = expense.currencyCode
      ..cadence = expense.cadence
      ..anchorDate = expense.anchorDate
      ..category = expense.category
      ..active = expense.active
      ..linkedAccountId = expense.linkedAccountId;
    await _expenses.upsert(existing);
  }

  Future<void> archive(String id) async {
    final e = _require(id);
    e.active = false;
    await _expenses.upsert(e);
  }

  Future<void> deleteById(String id) => _expenses.remove(id);

  RecurringExpense _require(String id) {
    final e = findById(id);
    if (e == null) throw StateError('RecurringExpense $id not found');
    return e;
  }
}

final recurringExpensesCloudProvider =
    Provider<CloudCollection<RecurringExpense>>((ref) {
  return CloudCollection<RecurringExpense>(
    collectionName: 'recurring_expenses',
    box: ref.watch(recurringExpensesBoxProvider),
    toJson: (e) => e.toJson(),
    fromJson: RecurringExpense.fromJson,
    idOf: (e) => e.id,
  );
});

final recurringExpenseRepositoryProvider =
    Provider<RecurringExpenseRepository>((ref) {
  return RecurringExpenseRepository(
    expenses: ref.watch(recurringExpensesCloudProvider),
    clock: ref.watch(clockProvider),
  );
});
