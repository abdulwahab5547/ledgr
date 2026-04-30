import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_bootstrap.dart';
import '../../../core/sync/cloud_collection.dart';
import 'app_prefs_model.dart';

class PrefsRepository {
  PrefsRepository({required CloudCollection<AppPrefs> prefs}) : _prefs = prefs;

  final CloudCollection<AppPrefs> _prefs;

  Box<AppPrefs> get _box => _prefs.box;

  AppPrefs read() {
    final existing = _box.get(AppPrefs.singletonKey);
    if (existing != null) return existing;
    final fresh = AppPrefs();
    // Persist the default — fire-and-forget so a fresh read returns
    // immediately. The cloud mirror picks up the same write.
    unawaited(_prefs.upsert(fresh));
    return fresh;
  }

  Stream<AppPrefs> watch() async* {
    yield read();
    yield* _box.watch(key: AppPrefs.singletonKey).map((_) => read());
  }

  Future<AppPrefs> update(AppPrefs Function(AppPrefs) mutate) async {
    final next = mutate(read());
    await _prefs.upsert(next);
    return next;
  }
}

final prefsCloudProvider = Provider<CloudCollection<AppPrefs>>((ref) {
  return CloudCollection<AppPrefs>(
    collectionName: 'app_prefs',
    box: ref.watch(prefsBoxProvider),
    toJson: (p) => p.toJson(),
    fromJson: AppPrefs.fromJson,
    // AppPrefs is a singleton — every write hits the same doc id.
    idOf: (_) => AppPrefs.singletonKey,
  );
});

final prefsRepositoryProvider = Provider<PrefsRepository>((ref) {
  return PrefsRepository(prefs: ref.watch(prefsCloudProvider));
});

final appPrefsProvider = StreamProvider<AppPrefs>((ref) {
  return ref.watch(prefsRepositoryProvider).watch();
});
