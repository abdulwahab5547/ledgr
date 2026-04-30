import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_bootstrap.dart';
import '../../../core/sync/cloud_collection.dart';
import '../../../core/time/clock.dart';
import 'incoming_payment_model.dart';

class IncomingPaymentRepository {
  IncomingPaymentRepository({
    required CloudCollection<IncomingPayment> payments,
    required Clock clock,
    Uuid? uuid,
  })  : _payments = payments,
        _clock = clock,
        _uuid = uuid ?? const Uuid();

  final CloudCollection<IncomingPayment> _payments;
  final Clock _clock;
  final Uuid _uuid;

  Box<IncomingPayment> get _box => _payments.box;

  List<IncomingPayment> listAll() => _box.values.toList(growable: false);

  List<IncomingPayment> listOpen() {
    final out = _box.values.where((p) => p.isOpen).toList()
      ..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));
    return out;
  }

  Stream<List<IncomingPayment>> watchOpen() async* {
    yield listOpen();
    yield* _box.watch().map((_) => listOpen());
  }

  Stream<List<IncomingPayment>> watchAll() async* {
    yield listAll();
    yield* _box.watch().map((_) => listAll());
  }

  IncomingPayment? findById(String id) {
    for (final p in _box.values) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<IncomingPayment> create({
    required String label,
    required int amountMinorUnits,
    required String currencyCode,
    required DateTime expectedDate,
    String? source,
  }) async {
    if (amountMinorUnits <= 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'Must be positive',
      );
    }
    final p = IncomingPayment(
      id: _uuid.v4(),
      label: label,
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
      expectedDate: expectedDate,
      createdAt: _clock.now(),
      source: source,
    );
    await _payments.upsert(p);
    return p;
  }

  Future<void> update(IncomingPayment payment) async {
    final existing = _require(payment.id);
    existing
      ..label = payment.label
      ..amountMinorUnits = payment.amountMinorUnits
      ..currencyCode = payment.currencyCode
      ..expectedDate = payment.expectedDate
      ..source = payment.source;
    await _payments.upsert(existing);
  }

  Future<void> markReceived({
    required String id,
    required DateTime when,
    required String linkedAccountId,
  }) async {
    final p = _require(id);
    p
      ..receivedAt = when
      ..linkedAccountId = linkedAccountId;
    await _payments.upsert(p);
  }

  /// Used only by [IncomingReceivedService] to roll back if the linked
  /// vault adjustment fails after the payment is marked received.
  Future<void> revertReceived(String id) async {
    final p = _require(id);
    p
      ..receivedAt = null
      ..linkedAccountId = null;
    await _payments.upsert(p);
  }

  Future<void> deleteById(String id) => _payments.remove(id);

  IncomingPayment _require(String id) {
    final p = findById(id);
    if (p == null) throw StateError('IncomingPayment $id not found');
    return p;
  }
}

final incomingPaymentsCloudProvider =
    Provider<CloudCollection<IncomingPayment>>((ref) {
  return CloudCollection<IncomingPayment>(
    collectionName: 'incoming_payments',
    box: ref.watch(incomingPaymentsBoxProvider),
    toJson: (p) => p.toJson(),
    fromJson: IncomingPayment.fromJson,
    idOf: (p) => p.id,
  );
});

final incomingPaymentRepositoryProvider =
    Provider<IncomingPaymentRepository>((ref) {
  return IncomingPaymentRepository(
    payments: ref.watch(incomingPaymentsCloudProvider),
    clock: ref.watch(clockProvider),
  );
});
