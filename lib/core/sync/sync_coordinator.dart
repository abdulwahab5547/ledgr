import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_providers.dart';
import 'cloud_collection.dart';

/// Glues every [CloudCollection] in the app to the live auth state.
///
/// On sign-in: every registered collection binds to the new user — pulls
/// their data from Firestore into Hive and starts a snapshot listener.
/// On sign-out: every collection releases its binding (Hive cache stays
/// for offline view, but no further writes hit Firestore).
class SyncCoordinator {
  SyncCoordinator(this._collections);

  final List<CloudCollection<Object?>> _collections;

  Future<void> bindTo(String? uid) async {
    await Future.wait([
      for (final c in _collections) c.bindToUser(uid),
    ]);
  }

  Future<void> dispose() async {
    await Future.wait([for (final c in _collections) c.dispose()]);
  }
}

/// Glue provider — every CloudCollection registers itself on this list.
/// New features wire their CloudCollection here so SyncCoordinator picks
/// them up automatically.
final cloudCollectionsProvider = Provider<List<CloudCollection<Object?>>>(
  (ref) => throw UnimplementedError(
    'cloudCollectionsProvider must be overridden in main.dart',
  ),
);

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coord = SyncCoordinator(ref.watch(cloudCollectionsProvider));
  ref.onDispose(coord.dispose);
  return coord;
});

/// Top-level listener. Read once during app init so the coordinator binds
/// itself to the active user and re-binds on auth state changes.
final syncBootstrapProvider = Provider<void>((ref) {
  final coord = ref.watch(syncCoordinatorProvider);
  ref.listen(
    authStateProvider,
    (_, next) {
      final user = next.valueOrNull;
      coord.bindTo(user?.uid);
    },
    fireImmediately: true,
  );
});
