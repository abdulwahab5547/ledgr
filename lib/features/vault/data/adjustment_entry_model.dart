import 'package:hive/hive.dart';

import '../../../core/storage/hive_bootstrap.dart';

/// Why a balance was changed. Lets the audit trail explain itself, and lets
/// later modules (Ledger settlement, Pipeline mark-as-received) post to the
/// same single audit pipeline.
enum AdjustmentReason {
  manual,
  quickAdjust,
  ledgerSettlement,
  pipelineReceived,
  burnPaid,
  initialBalance,
}

/// Append-only audit record for any change to an [Account] balance. Every
/// mutation in Ledgr — manual edit, quick adjust, settlement, etc. — writes
/// one of these. Net wealth at any past time is reconstructible from these
/// entries if a balance ever looks wrong.
class AdjustmentEntry extends HiveObject {
  AdjustmentEntry({
    required this.id,
    required this.accountId,
    required this.deltaMinorUnits,
    required this.balanceAfterMinorUnits,
    required this.reason,
    required this.occurredAt,
    this.note,
    this.linkedEntityId,
  });

  final String id;
  final String accountId;
  final int deltaMinorUnits;
  final int balanceAfterMinorUnits;
  final AdjustmentReason reason;
  final DateTime occurredAt;
  final String? note;

  /// Optional pointer to the originating object (a ledger entry, an
  /// incoming-payment record, etc.) so later modules can navigate from an
  /// audit row back to its source.
  final String? linkedEntityId;

  Map<String, Object?> toJson() => {
        'id': id,
        'accountId': accountId,
        'deltaMinorUnits': deltaMinorUnits,
        'balanceAfterMinorUnits': balanceAfterMinorUnits,
        'reason': reason.name,
        'occurredAt': occurredAt.toIso8601String(),
        'note': note,
        'linkedEntityId': linkedEntityId,
      };

  static AdjustmentEntry fromJson(Map<String, Object?> json) =>
      AdjustmentEntry(
        id: json['id']! as String,
        accountId: json['accountId']! as String,
        deltaMinorUnits: (json['deltaMinorUnits']! as num).toInt(),
        balanceAfterMinorUnits:
            (json['balanceAfterMinorUnits']! as num).toInt(),
        reason: AdjustmentReason.values.firstWhere(
          (r) => r.name == json['reason'],
          orElse: () => AdjustmentReason.manual,
        ),
        occurredAt: DateTime.parse(json['occurredAt']! as String),
        note: json['note'] as String?,
        linkedEntityId: json['linkedEntityId'] as String?,
      );
}

class AdjustmentEntryAdapter extends TypeAdapter<AdjustmentEntry> {
  @override
  final int typeId = HiveTypeIds.adjustmentEntry;

  @override
  AdjustmentEntry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return AdjustmentEntry(
      id: fields[0] as String,
      accountId: fields[1] as String,
      deltaMinorUnits: fields[2] as int,
      balanceAfterMinorUnits: fields[3] as int,
      reason: fields[4] as AdjustmentReason,
      occurredAt: fields[5] as DateTime,
      note: fields[6] as String?,
      linkedEntityId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AdjustmentEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.deltaMinorUnits)
      ..writeByte(3)
      ..write(obj.balanceAfterMinorUnits)
      ..writeByte(4)
      ..write(obj.reason)
      ..writeByte(5)
      ..write(obj.occurredAt)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.linkedEntityId);
  }
}

class AdjustmentReasonAdapter extends TypeAdapter<AdjustmentReason> {
  @override
  final int typeId = HiveTypeIds.adjustmentReason;

  @override
  AdjustmentReason read(BinaryReader reader) {
    final index = reader.readByte();
    if (index < 0 || index >= AdjustmentReason.values.length) {
      return AdjustmentReason.manual;
    }
    return AdjustmentReason.values[index];
  }

  @override
  void write(BinaryWriter writer, AdjustmentReason obj) {
    writer.writeByte(obj.index);
  }
}
