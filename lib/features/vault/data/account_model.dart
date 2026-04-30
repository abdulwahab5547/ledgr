import 'package:hive/hive.dart';

import '../../../core/money/money.dart';
import '../../../core/storage/hive_bootstrap.dart';

enum AccountType { bank, wallet, cash, other }

/// A user-defined storage location for liquid funds. Balance is persisted as
/// integer minor units to avoid floating point drift; the [balance] getter
/// wraps it in a [Money] value object for the domain layer.
class Account extends HiveObject {
  Account({
    required this.id,
    required this.label,
    required this.type,
    required this.balanceMinorUnits,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
  });

  final String id;
  String label;
  AccountType type;
  int balanceMinorUnits;
  String currencyCode;
  DateTime createdAt;
  DateTime updatedAt;
  bool archived;

  Money get balance =>
      Money(balanceMinorUnits, currencyCode: currencyCode);

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'balanceMinorUnits': balanceMinorUnits,
        'currencyCode': currencyCode,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'archived': archived,
      };

  static Account fromJson(Map<String, Object?> json) => Account(
        id: json['id']! as String,
        label: json['label']! as String,
        type: AccountType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => AccountType.other,
        ),
        balanceMinorUnits: (json['balanceMinorUnits']! as num).toInt(),
        currencyCode: json['currencyCode']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        updatedAt: DateTime.parse(json['updatedAt']! as String),
        archived: (json['archived'] as bool?) ?? false,
      );

  Account copyWith({
    String? label,
    AccountType? type,
    int? balanceMinorUnits,
    String? currencyCode,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return Account(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      balanceMinorUnits: balanceMinorUnits ?? this.balanceMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }
}

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = HiveTypeIds.account;

  @override
  Account read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as String,
      label: fields[1] as String,
      type: fields[2] as AccountType,
      balanceMinorUnits: fields[3] as int,
      currencyCode: fields[4] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      archived: (fields[7] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.balanceMinorUnits)
      ..writeByte(4)
      ..write(obj.currencyCode)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.archived);
  }
}

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = HiveTypeIds.accountType;

  @override
  AccountType read(BinaryReader reader) {
    final index = reader.readByte();
    if (index < 0 || index >= AccountType.values.length) {
      return AccountType.other;
    }
    return AccountType.values[index];
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    writer.writeByte(obj.index);
  }
}
