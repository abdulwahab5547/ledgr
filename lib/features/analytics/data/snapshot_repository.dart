import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_bootstrap.dart';
import '../../../core/sync/cloud_collection.dart';
import 'net_position_snapshot_model.dart';

class SnapshotRepository {
  SnapshotRepository({required CloudCollection<NetPositionSnapshot> snapshots})
      : _snapshots = snapshots;

  final CloudCollection<NetPositionSnapshot> _snapshots;

  Box<NetPositionSnapshot> get _box => _snapshots.box;

  bool exists(String dateKey) => _box.containsKey(dateKey);

  NetPositionSnapshot? get(String dateKey) => _box.get(dateKey);

  /// Sorted oldest → newest.
  List<NetPositionSnapshot> listAll() {
    final out = _box.values.toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return out;
  }

  Stream<List<NetPositionSnapshot>> watchAll() async* {
    yield listAll();
    yield* _box.watch().map((_) => listAll());
  }

  Future<void> put(NetPositionSnapshot s) => _snapshots.upsert(s);

  Future<void> deleteAll() => _box.clear();
}

final snapshotsCloudProvider =
    Provider<CloudCollection<NetPositionSnapshot>>((ref) {
  return CloudCollection<NetPositionSnapshot>(
    collectionName: 'net_position_snapshots',
    box: ref.watch(snapshotsBoxProvider),
    toJson: (s) => s.toJson(),
    fromJson: NetPositionSnapshot.fromJson,
    idOf: (s) => s.dateKey,
  );
});

final snapshotRepositoryProvider = Provider<SnapshotRepository>((ref) {
  return SnapshotRepository(snapshots: ref.watch(snapshotsCloudProvider));
});
