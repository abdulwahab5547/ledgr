import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/net_position_snapshot_model.dart';
import '../data/snapshot_repository.dart';

/// Live stream of every snapshot, oldest → newest.
final snapshotsStreamProvider = StreamProvider<List<NetPositionSnapshot>>(
  (ref) => ref.watch(snapshotRepositoryProvider).watchAll(),
);

/// The most recent N days of snapshots (or all of them if fewer).
final recentSnapshotsProvider =
    Provider.family<List<NetPositionSnapshot>, int>((ref, days) {
  final all = ref.watch(snapshotsStreamProvider).valueOrNull ?? const [];
  if (all.length <= days) return all;
  return all.sublist(all.length - days);
});
