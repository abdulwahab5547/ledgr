import 'package:flutter/material.dart';

import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/money/pkr_format.dart';
import '../../../../core/privacy/private_text.dart';
import '../../domain/pipeline_providers.dart';

/// List card showing upcoming invoices + recurring expense occurrences.
/// Items come from `upcomingItemsProvider`. Invoices are tappable so the
/// user can mark-received from anywhere on the row.
class UpcomingEventsCard extends StatelessWidget {
  const UpcomingEventsCard({
    required this.items,
    required this.onTapInvoice,
    required this.onTapExpense,
    super.key,
  });

  final List<UpcomingItem> items;
  final ValueChanged<UpcomingItem> onTapInvoice;
  final ValueChanged<UpcomingItem> onTapExpense;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return LedgrCard(
        padding: 22,
        child: Column(
          children: [
            Text(
              'Nothing scheduled',
              style:
                  LedgrType.serif(fontSize: 18, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
            Text(
              'Add an invoice or recurring expense to see it here.',
              textAlign: TextAlign.center,
              style: LedgrType.sans(fontSize: 13, color: LedgrColors.textDim),
            ),
          ],
        ),
      );
    }
    return LedgrCard.flush(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _Row(
              item: items[i],
              onTap: () => items[i].kind == UpcomingKind.invoice
                  ? onTapInvoice(items[i])
                  : onTapExpense(items[i]),
            ),
            if (i < items.length - 1)
              const Divider(height: 0.5, color: LedgrColors.hairline),
          ],
        ],
      ),
    );
  }
}

const _weekdayShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.onTap});
  final UpcomingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pos = item.amountMinorUnits >= 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x08FFFFFF),
                  border: Border.all(
                    color: LedgrColors.hairline,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      item.dueDate.day.toString().padLeft(2, '0'),
                      style: LedgrType.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _weekdayShort[item.dueDate.weekday - 1],
                      style: LedgrType.sans(
                        fontSize: 9,
                        color: LedgrColors.textMute,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: LedgrType.listTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.kind == UpcomingKind.invoice
                          ? 'INVOICE · TAP TO RECEIVE'
                          : 'RECURRING · AUTO',
                      style: LedgrType.eyebrow(
                        fontSize: 11,
                        color: LedgrColors.textMute,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              PrivateText.digits(
                PkrFormat.fromMinor(
                  item.amountMinorUnits,
                  sign: true,
                  includeSymbol: false,
                ),
                style: LedgrType.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: pos ? LedgrColors.pos : LedgrColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
