import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_bootstrap.dart';
import '../../../core/sync/cloud_collection.dart';
import '../../../core/time/clock.dart';
import 'ledger_entry_model.dart';

class LedgerRepository {
  LedgerRepository({
    required CloudCollection<LedgerEntry> entries,
    required Clock clock,
    Uuid? uuid,
  })  : _entries = entries,
        _clock = clock,
        _uuid = uuid ?? const Uuid();

  final CloudCollection<LedgerEntry> _entries;
  final Clock _clock;
  final Uuid _uuid;

  Box<LedgerEntry> get _box => _entries.box;

  List<LedgerEntry> listAll() => _box.values.toList(growable: false);

  /// All open (unsettled) entries, newest-first.
  List<LedgerEntry> listOpen() {
    final entries = _box.values.where((e) => e.isOpen).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Stream<List<LedgerEntry>> watchOpen() async* {
    yield listOpen();
    yield* _box.watch().map((_) => listOpen());
  }

  Stream<List<LedgerEntry>> watchAll() async* {
    yield listAll();
    yield* _box.watch().map((_) => listAll());
  }

  LedgerEntry? findById(String id) {
    for (final e in _box.values) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<LedgerEntry> create({
    required String contactId,
    required LedgerDirection direction,
    required int amountMinorUnits,
    required String currencyCode,
    String? note,
    DateTime? dueDate,
  }) async {
    if (amountMinorUnits <= 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'Must be positive — direction encodes lent vs borrowed',
      );
    }
    final entry = LedgerEntry(
      id: _uuid.v4(),
      contactId: contactId,
      direction: direction,
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
      createdAt: _clock.now(),
      note: note,
      dueDate: dueDate,
    );
    await _entries.upsert(entry);
    return entry;
  }

  Future<void> markSettled({
    required String entryId,
    required DateTime when,
    required String linkedAccountId,
  }) async {
    final entry = _require(entryId);
    entry
      ..settledAt = when
      ..linkedAccountId = linkedAccountId;
    await _entries.upsert(entry);
  }

  /// Used only by [SettlementService] to roll back a partial settlement when
  /// the linked Vault adjustment fails.
  Future<void> revertSettlement(String entryId) async {
    final entry = _require(entryId);
    entry
      ..settledAt = null
      ..linkedAccountId = null;
    await _entries.upsert(entry);
  }

  Future<void> deleteEntry(String entryId) => _entries.remove(entryId);

  LedgerEntry _require(String id) {
    final e = findById(id);
    if (e == null) throw StateError('LedgerEntry $id not found');
    return e;
  }
}

final ledgerEntriesCloudProvider =
    Provider<CloudCollection<LedgerEntry>>((ref) {
  return CloudCollection<LedgerEntry>(
    collectionName: 'ledger_entries',
    box: ref.watch(ledgerEntriesBoxProvider),
    toJson: (e) => e.toJson(),
    fromJson: LedgerEntry.fromJson,
    idOf: (e) => e.id,
  );
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(
    entries: ref.watch(ledgerEntriesCloudProvider),
    clock: ref.watch(clockProvider),
  );
});
