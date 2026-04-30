import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../data/contact_model.dart';
import '../data/contact_repository.dart';
import '../data/ledger_entry_model.dart';
import '../data/ledger_repository.dart';

class ContactBalance {
  const ContactBalance({
    required this.contact,
    required this.netSignedMinorUnits,
    required this.openLent,
    required this.openBorrowed,
  });

  final Contact contact;

  /// Positive => contact owes the user (net receivable).
  /// Negative => the user owes them (net payable).
  final int netSignedMinorUnits;

  final int openLent;
  final int openBorrowed;
}

/// Live stream of contacts.
final contactsStreamProvider = StreamProvider<List<Contact>>((ref) {
  return ref.watch(contactRepositoryProvider).watchActive();
});

/// Live stream of every open ledger entry.
final openEntriesStreamProvider = StreamProvider<List<LedgerEntry>>((ref) {
  return ref.watch(ledgerRepositoryProvider).watchOpen();
});

/// Per-contact open balance summary, keyed by contact id. Only includes
/// contacts that have at least one open entry (resolved contacts get pruned
/// from the Ledger UI).
final contactBalancesProvider = Provider<Map<String, ContactBalance>>((ref) {
  final contactsAsync = ref.watch(contactsStreamProvider);
  final entriesAsync = ref.watch(openEntriesStreamProvider);
  final contacts = contactsAsync.valueOrNull ?? const <Contact>[];
  final entries = entriesAsync.valueOrNull ?? const <LedgerEntry>[];
  return computeContactBalances(contacts: contacts, entries: entries);
});

/// Pure helper for tests.
Map<String, ContactBalance> computeContactBalances({
  required List<Contact> contacts,
  required List<LedgerEntry> entries,
}) {
  final byId = {for (final c in contacts) c.id: c};
  final aggregates = <String, _Agg>{};
  for (final e in entries) {
    final agg = aggregates.putIfAbsent(e.contactId, _Agg.new);
    if (e.isLent) {
      agg.lent += e.amountMinorUnits;
    } else {
      agg.borrowed += e.amountMinorUnits;
    }
  }
  return {
    for (final entry in aggregates.entries)
      if (byId[entry.key] != null)
        entry.key: ContactBalance(
          contact: byId[entry.key]!,
          netSignedMinorUnits: entry.value.lent - entry.value.borrowed,
          openLent: entry.value.lent,
          openBorrowed: entry.value.borrowed,
        ),
  };
}

class _Agg {
  int lent = 0;
  int borrowed = 0;
}

/// Currency-aware totals for the ledger header (Lent / Borrowed / Net).
final socialTotalsProvider = Provider<SocialTotals>((ref) {
  final entries = ref.watch(openEntriesStreamProvider).valueOrNull ?? const [];
  return SocialTotals.fromEntries(entries);
});

class SocialTotals {
  const SocialTotals({
    required this.lent,
    required this.borrowed,
    required this.net,
    required this.lentCount,
    required this.borrowedCount,
    required this.currencyCode,
  });

  final Money lent;
  final Money borrowed;
  final Money net;
  final int lentCount;
  final int borrowedCount;
  final String currencyCode;

  bool get isEmpty => lentCount == 0 && borrowedCount == 0;

  factory SocialTotals.fromEntries(List<LedgerEntry> entries) {
    if (entries.isEmpty) {
      return const SocialTotals(
        lent: Money(0, currencyCode: 'PKR'),
        borrowed: Money(0, currencyCode: 'PKR'),
        net: Money(0, currencyCode: 'PKR'),
        lentCount: 0,
        borrowedCount: 0,
        currencyCode: 'PKR',
      );
    }
    final byCurrency = <String, _CurrencyAgg>{};
    for (final e in entries) {
      final agg = byCurrency.putIfAbsent(e.currencyCode, _CurrencyAgg.new);
      if (e.isLent) {
        agg.lent += e.amountMinorUnits;
        agg.lentCount += 1;
      } else {
        agg.borrowed += e.amountMinorUnits;
        agg.borrowedCount += 1;
      }
    }
    // Use the first currency as the primary reporting bucket. Multi-currency
    // social ledgers will be addressed in Module 5's currency conversion.
    final primary = byCurrency.entries.first;
    final agg = primary.value;
    return SocialTotals(
      lent: Money(agg.lent, currencyCode: primary.key),
      borrowed: Money(agg.borrowed, currencyCode: primary.key),
      net: Money(agg.lent - agg.borrowed, currencyCode: primary.key),
      lentCount: agg.lentCount,
      borrowedCount: agg.borrowedCount,
      currencyCode: primary.key,
    );
  }
}

class _CurrencyAgg {
  int lent = 0;
  int borrowed = 0;
  int lentCount = 0;
  int borrowedCount = 0;
}
