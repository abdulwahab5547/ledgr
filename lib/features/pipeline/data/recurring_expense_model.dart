import 'package:hive/hive.dart';

import '../../../core/storage/hive_bootstrap.dart';
import 'expense_category.dart';

/// Cadence at which a recurring expense fires. Stored as enum index.
enum Cadence { weekly, monthly, yearly }

extension CadenceX on Cadence {
  String get label => switch (this) {
        Cadence.weekly => 'Weekly',
        Cadence.monthly => 'Monthly',
        Cadence.yearly => 'Yearly',
      };

  /// Multiplier to convert one occurrence to a monthly-equivalent amount.
  /// Used by the Vault burn-rate metric and the Pipeline donut center number.
  double get monthlyMultiplier => switch (this) {
        Cadence.weekly => 52 / 12,
        Cadence.monthly => 1,
        Cadence.yearly => 1 / 12,
      };
}

/// A recurring outflow: subscription, rent, salary outflow, etc.
///
/// [anchorDate] is the seed date for occurrence generation. The
/// `RecurrenceEngine` walks forward from this date through any window the
/// caller asks for. For monthly/yearly cadence the day-of-month is preserved
/// where possible, clamping into the target month (e.g. anchor on Jan 31 →
/// Feb 28 in non-leap years, Feb 29 in leap years).
class RecurringExpense extends HiveObject {
  RecurringExpense({
    required this.id,
    required this.label,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.cadence,
    required this.anchorDate,
    required this.category,
    required this.createdAt,
    this.active = true,
    this.linkedAccountId,
  });

  final String id;
  String label;
  int amountMinorUnits;
  String currencyCode;
  Cadence cadence;
  DateTime anchorDate;
  ExpenseCategory category;
  DateTime createdAt;
  bool active;

  /// When set, "mark paid" on a generated occurrence will post the
  /// adjustment to this account. (Wiring lands in a later iteration.)
  String? linkedAccountId;

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'amountMinorUnits': amountMinorUnits,
        'currencyCode': currencyCode,
        'cadence': cadence.name,
        'anchorDate': anchorDate.toIso8601String(),
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
        'active': active,
        'linkedAccountId': linkedAccountId,
      };

  static RecurringExpense fromJson(Map<String, Object?> json) =>
      RecurringExpense(
        id: json['id']! as String,
        label: json['label']! as String,
        amountMinorUnits: (json['amountMinorUnits']! as num).toInt(),
        currencyCode: json['currencyCode']! as String,
        cadence: Cadence.values.firstWhere(
          (c) => c.name == json['cadence'],
          orElse: () => Cadence.monthly,
        ),
        anchorDate: DateTime.parse(json['anchorDate']! as String),
        category: ExpenseCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        createdAt: DateTime.parse(json['createdAt']! as String),
        active: (json['active'] as bool?) ?? true,
        linkedAccountId: json['linkedAccountId'] as String?,
      );
}

class RecurringExpenseAdapter extends TypeAdapter<RecurringExpense> {
  @override
  final int typeId = HiveTypeIds.recurringExpense;

  @override
  RecurringExpense read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return RecurringExpense(
      id: fields[0] as String,
      label: fields[1] as String,
      amountMinorUnits: fields[2] as int,
      currencyCode: fields[3] as String,
      cadence: fields[4] as Cadence,
      anchorDate: fields[5] as DateTime,
      category: fields[6] as ExpenseCategory,
      createdAt: fields[7] as DateTime,
      active: (fields[8] as bool?) ?? true,
      linkedAccountId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringExpense obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.amountMinorUnits)
      ..writeByte(3)
      ..write(obj.currencyCode)
      ..writeByte(4)
      ..write(obj.cadence)
      ..writeByte(5)
      ..write(obj.anchorDate)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.active)
      ..writeByte(9)
      ..write(obj.linkedAccountId);
  }
}

class CadenceAdapter extends TypeAdapter<Cadence> {
  @override
  final int typeId = HiveTypeIds.cadence;

  @override
  Cadence read(BinaryReader reader) {
    final i = reader.readByte();
    return i < Cadence.values.length ? Cadence.values[i] : Cadence.monthly;
  }

  @override
  void write(BinaryWriter writer, Cadence obj) {
    writer.writeByte(obj.index);
  }
}
