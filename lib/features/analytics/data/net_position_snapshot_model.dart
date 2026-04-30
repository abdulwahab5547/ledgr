import 'package:hive/hive.dart';

import '../../../core/storage/hive_bootstrap.dart';

/// One day's frozen view of net position. Written once per day (key =
/// "yyyy-MM-dd") so re-running the snapshotter is idempotent.
///
/// `trueLiquidityMinor` is stored as the live value at the time the
/// snapshot was taken (assets + 30d incoming − payables − 30d burn). For
/// backfilled days from the audit trail we leave it null — we can't
/// reconstruct historical projections accurately.
class NetPositionSnapshot extends HiveObject {
  NetPositionSnapshot({
    required this.dateKey,
    required this.totalAssetsMinor,
    required this.netReceivableMinor,
    required this.netPayableMinor,
    required this.currencyCode,
    required this.takenAt,
    this.trueLiquidityMinor,
  });

  /// `yyyy-MM-dd` — also the Hive key. Stored on the object too so a single
  /// `box.values` scan is enough to drive the trend chart.
  final String dateKey;

  final int totalAssetsMinor;
  final int netReceivableMinor;
  final int netPayableMinor;

  /// Optional — only populated for snapshots taken live (not backfilled).
  final int? trueLiquidityMinor;

  final String currencyCode;
  final DateTime takenAt;

  /// Same-day reconstruction shortcut.
  int get netAssetsMinor =>
      totalAssetsMinor + netReceivableMinor - netPayableMinor;

  static String formatDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Map<String, Object?> toJson() => {
        'dateKey': dateKey,
        'totalAssetsMinor': totalAssetsMinor,
        'netReceivableMinor': netReceivableMinor,
        'netPayableMinor': netPayableMinor,
        'currencyCode': currencyCode,
        'takenAt': takenAt.toIso8601String(),
        'trueLiquidityMinor': trueLiquidityMinor,
      };

  static NetPositionSnapshot fromJson(Map<String, Object?> json) =>
      NetPositionSnapshot(
        dateKey: json['dateKey']! as String,
        totalAssetsMinor: (json['totalAssetsMinor']! as num).toInt(),
        netReceivableMinor: (json['netReceivableMinor']! as num).toInt(),
        netPayableMinor: (json['netPayableMinor']! as num).toInt(),
        currencyCode: json['currencyCode']! as String,
        takenAt: DateTime.parse(json['takenAt']! as String),
        trueLiquidityMinor:
            (json['trueLiquidityMinor'] as num?)?.toInt(),
      );
}

class NetPositionSnapshotAdapter extends TypeAdapter<NetPositionSnapshot> {
  @override
  final int typeId = HiveTypeIds.netPositionSnapshot;

  @override
  NetPositionSnapshot read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return NetPositionSnapshot(
      dateKey: fields[0] as String,
      totalAssetsMinor: fields[1] as int,
      netReceivableMinor: fields[2] as int,
      netPayableMinor: fields[3] as int,
      currencyCode: fields[4] as String,
      takenAt: fields[5] as DateTime,
      trueLiquidityMinor: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, NetPositionSnapshot obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.totalAssetsMinor)
      ..writeByte(2)
      ..write(obj.netReceivableMinor)
      ..writeByte(3)
      ..write(obj.netPayableMinor)
      ..writeByte(4)
      ..write(obj.currencyCode)
      ..writeByte(5)
      ..write(obj.takenAt)
      ..writeByte(6)
      ..write(obj.trueLiquidityMinor);
  }
}
