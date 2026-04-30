import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/ledgr_card.dart';
import '../../../core/design/components/ledgr_dashed_button.dart';
import '../../../core/design/components/ledgr_icon_button.dart';
import '../../../core/design/components/ledgr_screen_header.dart';
import '../../../core/design/components/ledgr_segmented.dart';
import '../../../core/design/ledgr_colors.dart';
import '../../../core/design/ledgr_typography.dart';
import '../../../core/money/pkr_format.dart';
import '../../../core/privacy/private_text.dart';
import '../../../core/time/clock.dart';
import '../data/contact_model.dart';
import '../data/ledger_entry_model.dart';
import '../domain/social_balances_provider.dart';
import 'widgets/contact_card.dart';
import 'widgets/entry_form_sheet.dart';
import 'widgets/settle_sheet.dart';
import 'widgets/twin_totals.dart';

enum LedgerFilter { all, lent, borrowed }

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  LedgerFilter _filter = LedgerFilter.all;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(openEntriesStreamProvider);
    final contacts = ref.watch(contactsStreamProvider).valueOrNull ?? const [];
    final totals = ref.watch(socialTotalsProvider);
    final now = ref.watch(clockProvider).now();

    final entries = entriesAsync.valueOrNull ?? const <LedgerEntry>[];
    final filtered = entries.where((e) {
      switch (_filter) {
        case LedgerFilter.all:
          return true;
        case LedgerFilter.lent:
          return e.isLent;
        case LedgerFilter.borrowed:
          return e.isBorrowed;
      }
    }).toList();

    final contactsById = {for (final c in contacts) c.id: c};

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 130),
          children: [
            LedgrScreenHeader(
              eyebrow: 'Social Ledger',
              titleItalic: 'Net ',
              titleRegular: PkrFormat.money(totals.net),
              trailing: LedgrIconButton(
                onTap: () => EntryFormSheet.show(context),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: LedgrColors.text,
                ),
              ),
            ),
            const SizedBox(height: 22),
            TwinTotals(
              lent: totals.lent,
              borrowed: totals.borrowed,
              lentCount: totals.lentCount,
              borrowedCount: totals.borrowedCount,
            ),
            const SizedBox(height: 18),
            LedgrSegmented<LedgerFilter>(
              segments: [
                LedgrSegment(
                  value: LedgerFilter.all,
                  label: 'All · ${entries.length}',
                ),
                LedgrSegment(
                  value: LedgerFilter.lent,
                  label: 'Lent · ${totals.lentCount}',
                ),
                LedgrSegment(
                  value: LedgerFilter.borrowed,
                  label: 'Borrowed · ${totals.borrowedCount}',
                ),
              ],
              value: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              _EmptyState(
                hasAny: entries.isNotEmpty,
                onAdd: () => EntryFormSheet.show(context),
              )
            else
              ..._buildList(filtered, contactsById, now),
            const SizedBox(height: 12),
            LedgrDashedButton(
              icon: Icons.add,
              label: 'New entry',
              onPressed: () => EntryFormSheet.show(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildList(
    List<LedgerEntry> entries,
    Map<String, Contact> contactsById,
    DateTime now,
  ) {
    return [
      for (final entry in entries) ...[
        Builder(
          builder: (context) {
            final contact = contactsById[entry.contactId];
            if (contact == null) return const SizedBox.shrink();
            return ContactCard(
              data: ContactCardData(
                contact: contact,
                entry: entry,
                now: now,
              ),
              onSettle: () => SettleSheet.show(
                context,
                entry: entry,
                contact: contact,
              ),
              onSecondary: () {},
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAny, required this.onAdd});

  final bool hasAny;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LedgrCard(
      padding: 26,
      child: Column(
        children: [
          Text(
            hasAny ? 'Nothing in this view' : 'Your ledger is empty',
            style: LedgrType.serif(fontSize: 20, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          Text(
            hasAny
                ? 'Switch filter to see other entries.'
                : "Track who you've lent to or borrowed from.",
            textAlign: TextAlign.center,
            style: LedgrType.sans(
              fontSize: 13,
              color: LedgrColors.textDim,
            ),
          ),
          if (!hasAny) ...[
            const SizedBox(height: 14),
            PrivateText.digits(
              '— · —',
              style: LedgrType.mono(
                fontSize: 11,
                color: LedgrColors.textFaint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
