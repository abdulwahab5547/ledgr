import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_bootstrap.dart';
import '../../../core/sync/cloud_collection.dart';
import '../../../core/time/clock.dart';
import 'contact_model.dart';

class ContactRepository {
  ContactRepository({
    required CloudCollection<Contact> contacts,
    required Clock clock,
    Uuid? uuid,
  })  : _contacts = contacts,
        _clock = clock,
        _uuid = uuid ?? const Uuid();

  final CloudCollection<Contact> _contacts;
  final Clock _clock;
  final Uuid _uuid;

  Box<Contact> get _box => _contacts.box;

  List<Contact> listActive() => _box.values
      .where((c) => !c.archived)
      .toList(growable: false)
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Stream<List<Contact>> watchActive() async* {
    yield listActive();
    yield* _box.watch().map((_) => listActive());
  }

  Contact? findById(String id) {
    for (final c in _box.values) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<Contact> create({required String name, String? phone}) async {
    final c = Contact(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      createdAt: _clock.now(),
    );
    await _contacts.upsert(c);
    return c;
  }

  Future<Contact> rename(String id, String name) async {
    final c = _require(id);
    c.name = name;
    await _contacts.upsert(c);
    return c;
  }

  Future<void> archive(String id) async {
    final c = _require(id);
    c.archived = true;
    await _contacts.upsert(c);
  }

  Contact _require(String id) {
    final c = findById(id);
    if (c == null) throw StateError('Contact $id not found');
    return c;
  }
}

final contactsCloudProvider = Provider<CloudCollection<Contact>>((ref) {
  return CloudCollection<Contact>(
    collectionName: 'contacts',
    box: ref.watch(contactsBoxProvider),
    toJson: (c) => c.toJson(),
    fromJson: Contact.fromJson,
    idOf: (c) => c.id,
  );
});

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(
    contacts: ref.watch(contactsCloudProvider),
    clock: ref.watch(clockProvider),
  );
});
