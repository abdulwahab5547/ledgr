import 'package:hive/hive.dart';

import '../../../core/storage/hive_bootstrap.dart';

/// A person in the user's social ledger. Lightweight by design — name is
/// the only required field. Phone/note are optional and never leave the
/// device.
class Contact extends HiveObject {
  Contact({
    required this.id,
    required this.name,
    required this.createdAt,
    this.phone,
    this.archived = false,
  });

  final String id;
  String name;
  String? phone;
  DateTime createdAt;
  bool archived;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  static Contact fromJson(Map<String, Object?> json) => Contact(
        id: json['id']! as String,
        name: json['name']! as String,
        phone: json['phone'] as String?,
        createdAt: DateTime.parse(json['createdAt']! as String),
        archived: (json['archived'] as bool?) ?? false,
      );
}

class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = HiveTypeIds.contact;

  @override
  Contact read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return Contact(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String?,
      createdAt: fields[3] as DateTime,
      archived: (fields[4] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.archived);
  }
}
