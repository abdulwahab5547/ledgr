import 'package:hive/hive.dart';

import '../../../core/storage/hive_bootstrap.dart';

/// Persistent user preferences. There's exactly one instance, stored under
/// the singleton key [AppPrefs.singletonKey].
class AppPrefs extends HiveObject {
  AppPrefs({
    this.requireBiometricOnLaunch = true,
    this.privacyDefaultOn = false,
    this.primaryCurrency = 'PKR',
  });

  static const String singletonKey = 'singleton';

  bool requireBiometricOnLaunch;
  bool privacyDefaultOn;
  String primaryCurrency;

  AppPrefs copyWith({
    bool? requireBiometricOnLaunch,
    bool? privacyDefaultOn,
    String? primaryCurrency,
  }) {
    return AppPrefs(
      requireBiometricOnLaunch:
          requireBiometricOnLaunch ?? this.requireBiometricOnLaunch,
      privacyDefaultOn: privacyDefaultOn ?? this.privacyDefaultOn,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
    );
  }

  Map<String, Object?> toJson() => {
        'requireBiometricOnLaunch': requireBiometricOnLaunch,
        'privacyDefaultOn': privacyDefaultOn,
        'primaryCurrency': primaryCurrency,
      };

  static AppPrefs fromJson(Map<String, Object?> json) => AppPrefs(
        requireBiometricOnLaunch:
            (json['requireBiometricOnLaunch'] as bool?) ?? true,
        privacyDefaultOn: (json['privacyDefaultOn'] as bool?) ?? false,
        primaryCurrency: (json['primaryCurrency'] as String?) ?? 'PKR',
      );
}

class AppPrefsAdapter extends TypeAdapter<AppPrefs> {
  @override
  final int typeId = HiveTypeIds.appPrefs;

  @override
  AppPrefs read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return AppPrefs(
      requireBiometricOnLaunch: (fields[0] as bool?) ?? true,
      privacyDefaultOn: (fields[1] as bool?) ?? false,
      primaryCurrency: (fields[2] as String?) ?? 'PKR',
    );
  }

  @override
  void write(BinaryWriter writer, AppPrefs obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.requireBiometricOnLaunch)
      ..writeByte(1)
      ..write(obj.privacyDefaultOn)
      ..writeByte(2)
      ..write(obj.primaryCurrency);
  }
}
