import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal contract for the underlying secure store. Lets tests inject an
/// in-memory fake without spinning up platform channels.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class _SecureStorageBacked implements SecureKeyValueStore {
  _SecureStorageBacked()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Manages the AES-256 key used to encrypt every Hive box.
///
/// The key is generated once on first launch, stored in the OS secure enclave
/// via [FlutterSecureStorage], and reused on every subsequent launch. The raw
/// bytes never leave the device and are never logged.
class EncryptionKeyService {
  EncryptionKeyService({
    SecureKeyValueStore? storage,
    Random? random,
  })  : _storage = storage ?? _SecureStorageBacked(),
        _random = random ?? Random.secure();

  static const _storageKey = 'ledgr.hive.master_key.v1';
  static const _keyLengthBytes = 32; // 256 bits

  final SecureKeyValueStore _storage;
  final Random _random;

  /// Returns the 32-byte AES-256 key, generating it on first call.
  Future<List<int>> getOrCreateKey() async {
    final existing = await _storage.read(_storageKey);
    if (existing != null) {
      try {
        final decoded = base64Decode(existing);
        if (decoded.length == _keyLengthBytes) return decoded;
      } on FormatException {
        // Stored value was corrupted — fall through and generate fresh.
      }
    }
    final fresh = _generate();
    await _storage.write(_storageKey, base64Encode(fresh));
    return fresh;
  }

  /// Wipes the master key. After this call every encrypted box becomes
  /// permanently unreadable. Used by the "Wipe Data" settings action.
  Future<void> destroyKey() => _storage.delete(_storageKey);

  List<int> _generate() =>
      List<int>.generate(_keyLengthBytes, (_) => _random.nextInt(256));
}
