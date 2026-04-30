import 'package:hive/hive.dart';

import '../../../core/storage/hive_bootstrap.dart';

/// Direction of a social ledger entry, from the user's POV.
enum LedgerDirection {
  /// User lent money — the contact owes them. Positive receivable.
  lent,

  /// User borrowed money — they owe the contact. Negative payable.
  borrowed,
}

/// A single IOU between the user and a [Contact]. While [settledAt] is null
/// the entry is open. When settled, [linkedAccountId] points at the Vault
/// account the offsetting [AdjustmentEntry] was posted to.
class LedgerEntry extends HiveObject {
  LedgerEntry({
    required this.id,
    required this.contactId,
    required this.direction,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.createdAt,
    this.note,
    this.dueDate,
    this.settledAt,
    this.linkedAccountId,
  });

  final String id;
  final String contactId;
  final LedgerDirection direction;
  final int amountMinorUnits;
  final String currencyCode;
  final DateTime createdAt;
  String? note;
  DateTime? dueDate;
  DateTime? settledAt;
  String? linkedAccountId;

  bool get isOpen => settledAt == null;
  bool get isLent => direction == LedgerDirection.lent;
  bool get isBorrowed => direction == LedgerDirection.borrowed;

  /// Signed amount from the user's POV: positive when receivable, negative
  /// when payable. Useful for net calculations.
  int get signedMinorUnits =>
      isLent ? amountMinorUnits : -amountMinorUnits;

  Map<String, Object?> toJson() => {
        'id': id,
        'contactId': contactId,
        'direction': direction.name,
        'amountMinorUnits': amountMinorUnits,
        'currencyCode': currencyCode,
        'createdAt': createdAt.toIso8601String(),
        'note': note,
        'dueDate': dueDate?.toIso8601String(),
        'settledAt': settledAt?.toIso8601String(),
        'linkedAccountId': linkedAccountId,
      };

  static LedgerEntry fromJson(Map<String, Object?> json) => LedgerEntry(
        id: json['id']! as String,
        contactId: json['contactId']! as String,
        direction: LedgerDirection.values.firstWhere(
          (d) => d.name == json['direction'],
          orElse: () => LedgerDirection.lent,
        ),
        amountMinorUnits: (json['amountMinorUnits']! as num).toInt(),
        currencyCode: json['currencyCode']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        note: json['note'] as String?,
        dueDate: (json['dueDate'] as String?) == null
            ? null
            : DateTime.parse(json['dueDate']! as String),
        settledAt: (json['settledAt'] as String?) == null
            ? null
            : DateTime.parse(json['settledAt']! as String),
        linkedAccountId: json['linkedAccountId'] as String?,
      );
}

class LedgerEntryAdapter extends TypeAdapter<LedgerEntry> {
  @override
  final int typeId = HiveTypeIds.ledgerEntry;

  @override
  LedgerEntry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return LedgerEntry(
      id: fields[0] as String,
      contactId: fields[1] as String,
      direction: fields[2] as LedgerDirection,
      amountMinorUnits: fields[3] as int,
      currencyCode: fields[4] as String,
      createdAt: fields[5] as DateTime,
      note: fields[6] as String?,
      dueDate: fields[7] as DateTime?,
      settledAt: fields[8] as DateTime?,
      linkedAccountId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.contactId)
      ..writeByte(2)
      ..write(obj.direction)
      ..writeByte(3)
      ..write(obj.amountMinorUnits)
      ..writeByte(4)
      ..write(obj.currencyCode)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.dueDate)
      ..writeByte(8)
      ..write(obj.settledAt)
      ..writeByte(9)
      ..write(obj.linkedAccountId);
  }
}

class LedgerDirectionAdapter extends TypeAdapter<LedgerDirection> {
  @override
  final int typeId = HiveTypeIds.ledgerDirection;

  @override
  LedgerDirection read(BinaryReader reader) {
    final i = reader.readByte();
    return i < LedgerDirection.values.length
        ? LedgerDirection.values[i]
        : LedgerDirection.lent;
  }

  @override
  void write(BinaryWriter writer, LedgerDirection obj) {
    writer.writeByte(obj.index);
  }
}
