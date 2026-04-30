import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

/// Generic write-through wrapper around a Hive [Box] paired with a
/// per-user Firestore collection at `users/<uid>/<boxName>`.
///
/// Writes go to Hive immediately AND to Firestore (when bound to a user).
/// Remote changes flow back into Hive via a snapshot listener, so a sign-in
/// on another device picks up the same data.
///
/// Conflict policy is last-write-wins: Firestore is treated as the source
/// of truth on hydration. Local-only data created BEFORE the user signs in
/// is not auto-migrated — the user re-creates it after sign-in.
class CloudCollection<T> {
  CloudCollection({
    required this.collectionName,
    required Box<T> box,
    required this.toJson,
    required this.fromJson,
    required this.idOf,
    FirebaseFirestore? firestore,
  })  : _box = box,
        _explicitFirestore = firestore;

  /// Name of the subcollection under `users/<uid>/`. Stays stable across
  /// versions — changing it orphans every user's data, so don't.
  final String collectionName;

  final Box<T> _box;
  final FirebaseFirestore? _explicitFirestore;

  /// Lazy resolve so tests / offline mode can construct a CloudCollection
  /// without initialising Firebase. As long as nothing calls [bindToUser]
  /// or signs in, the Firestore instance is never touched.
  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;
  final Map<String, Object?> Function(T) toJson;
  final T Function(Map<String, Object?>) fromJson;
  final String Function(T) idOf;

  String? _uid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;

  /// True when bound to a signed-in user and ready to mirror writes.
  bool get isOnline => _uid != null;

  /// Underlying Hive box. Reads still go through this directly so existing
  /// repository APIs (`box.values`, `box.watch()`) keep working unchanged.
  Box<T> get box => _box;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection(collectionName);
  }

  /// Persist [item] locally and (when signed in) mirror to Firestore.
  Future<void> upsert(T item) async {
    final id = idOf(item);
    await _box.put(id, item);
    final col = _collection;
    if (col != null) {
      await col.doc(id).set({
        ...toJson(item),
        '_updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Remove [id] locally and (when signed in) from Firestore.
  Future<void> remove(String id) async {
    await _box.delete(id);
    await _collection?.doc(id).delete();
  }

  /// Bind to a user (sign-in) or clear the binding (sign-out).
  ///
  /// On bind: cancels the previous listener, downloads the user's docs into
  /// Hive (overwriting any local conflicts), and starts a live listener so
  /// remote edits land here automatically.
  ///
  /// On unbind (uid == null): cancels the listener. Local Hive data stays
  /// as a cache for offline view; the next sign-in re-hydrates from the
  /// cloud and replaces it.
  Future<void> bindToUser(String? uid) async {
    if (_uid == uid) return;
    await _remoteSub?.cancel();
    _remoteSub = null;
    _uid = uid;
    if (uid == null) return;

    final col = _collection!;
    // Initial hydration — pull every doc into Hive.
    try {
      final snap = await col.get();
      for (final doc in snap.docs) {
        await _box.put(doc.id, fromJson(doc.data()));
      }
    } catch (_) {
      // Network or permission failure on initial fetch is non-fatal —
      // the snapshot listener below will retry.
    }

    _remoteSub = col.snapshots().listen(
      (snap) async {
        for (final change in snap.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              final data = change.doc.data();
              if (data != null) {
                await _box.put(change.doc.id, fromJson(data));
              }
            case DocumentChangeType.removed:
              await _box.delete(change.doc.id);
          }
        }
      },
      onError: (Object _) {
        // Drop transient stream errors; the listener auto-recovers.
      },
    );
  }

  Future<void> dispose() async {
    await _remoteSub?.cancel();
    _remoteSub = null;
  }
}
