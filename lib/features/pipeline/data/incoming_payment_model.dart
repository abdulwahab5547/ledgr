import 'package:hive/hive.dart';

import '../../../core/storage/hive_bootstrap.dart';

/// An expected (not-yet-received) incoming payment — invoice, salary, gift.
/// While [receivedAt] is null the payment is part of the in-window incoming
/// total and shows up on the Pipeline upcoming list. When the user marks it
/// received, [IncomingReceivedService] posts an [AdjustmentEntry] to the
/// linked Vault account and stamps [receivedAt] / [linkedAccountId] here.
class IncomingPayment extends HiveObject {
  IncomingPayment({
    required this.id,
    required this.label,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.expectedDate,
    required this.createdAt,
    this.source,
    this.receivedAt,
    this.linkedAccountId,
  });

  final String id;
  String label;
  int amountMinorUnits;
  String currencyCode;
  DateTime expectedDate;
  DateTime createdAt;

  /// Free-form origin label (e.g. "Acme Corp", "Salary"). Optional.
  String? source;

  DateTime? receivedAt;
  String? linkedAccountId;

  bool get isOpen => receivedAt == null;

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'amountMinorUnits': amountMinorUnits,
        'currencyCode': currencyCode,
        'expectedDate': expectedDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'source': source,
        'receivedAt': receivedAt?.toIso8601String(),
        'linkedAccountId': linkedAccountId,
      };

  static IncomingPayment fromJson(Map<String, Object?> json) =>
      IncomingPayment(
        id: json['id']! as String,
        label: json['label']! as String,
        amountMinorUnits: (json['amountMinorUnits']! as num).toInt(),
        currencyCode: json['currencyCode']! as String,
        expectedDate: DateTime.parse(json['expectedDate']! as String),
        createdAt: DateTime.parse(json['createdAt']! as String),
        source: json['source'] as String?,
        receivedAt: (json['receivedAt'] as String?) == null
            ? null
            : DateTime.parse(json['receivedAt']! as String),
        linkedAccountId: json['linkedAccountId'] as String?,
      );
}

class IncomingPaymentAdapter extends TypeAdapter<IncomingPayment> {
  @override
  final int typeId = HiveTypeIds.incomingPayment;

  @override
  IncomingPayment read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return IncomingPayment(
      id: fields[0] as String,
      label: fields[1] as String,
      amountMinorUnits: fields[2] as int,
      currencyCode: fields[3] as String,
      expectedDate: fields[4] as DateTime,
      createdAt: fields[5] as DateTime,
      source: fields[6] as String?,
      receivedAt: fields[7] as DateTime?,
      linkedAccountId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, IncomingPayment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.amountMinorUnits)
      ..writeByte(3)
      ..write(obj.currencyCode)
      ..writeByte(4)
      ..write(obj.expectedDate)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.receivedAt)
      ..writeByte(8)
      ..write(obj.linkedAccountId);
  }
}
