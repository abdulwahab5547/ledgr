import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../core/design/ledgr_colors.dart';
import '../../../core/storage/hive_bootstrap.dart';

/// Closed set of expense categories used by the Pipeline donut chart and the
/// recurring-expense classifier. Stored as enum index (Hive type 23) so adding
/// values appends safely; never reorder existing entries.
enum ExpenseCategory {
  rent,
  salaries,
  subscriptions,
  utilities,
  food,
  transport,
  travel,
  tech,
  healthcare,
  entertainment,
  other,
}

extension ExpenseCategoryX on ExpenseCategory {
  String get label => switch (this) {
        ExpenseCategory.rent => 'Rent',
        ExpenseCategory.salaries => 'Salaries',
        ExpenseCategory.subscriptions => 'Subscriptions',
        ExpenseCategory.utilities => 'Utilities',
        ExpenseCategory.food => 'Food',
        ExpenseCategory.transport => 'Transport',
        ExpenseCategory.travel => 'Travel',
        ExpenseCategory.tech => 'Tech',
        ExpenseCategory.healthcare => 'Healthcare',
        ExpenseCategory.entertainment => 'Entertainment',
        ExpenseCategory.other => 'Other',
      };

  /// Donut palette mirrors the design bundle's recurring-expenses chart.
  /// Categories beyond the design's five reuse the same hue rotation so the
  /// chart stays visually coherent.
  Color get color => switch (this) {
        ExpenseCategory.rent => LedgrColors.lime,
        ExpenseCategory.salaries => LedgrColors.pos,
        ExpenseCategory.subscriptions => LedgrColors.tintTeal,
        ExpenseCategory.utilities => LedgrColors.tintViolet,
        ExpenseCategory.food => LedgrColors.tintAmber,
        ExpenseCategory.transport => LedgrColors.tintBlue,
        ExpenseCategory.travel => const Color(0xFFE85EAA),
        ExpenseCategory.tech => const Color(0xFF5EEAD4),
        ExpenseCategory.healthcare => const Color(0xFFFF8A6E),
        ExpenseCategory.entertainment => const Color(0xFFFFD56E),
        ExpenseCategory.other => const Color(0x2EFFFFFF),
      };
}

class ExpenseCategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final int typeId = HiveTypeIds.expenseCategory;

  @override
  ExpenseCategory read(BinaryReader reader) {
    final i = reader.readByte();
    return i < ExpenseCategory.values.length
        ? ExpenseCategory.values[i]
        : ExpenseCategory.other;
  }

  @override
  void write(BinaryWriter writer, ExpenseCategory obj) {
    writer.writeByte(obj.index);
  }
}
