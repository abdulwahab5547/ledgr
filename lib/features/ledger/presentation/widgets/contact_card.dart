import 'package:flutter/material.dart';

import '../../../../core/design/components/ledgr_avatar.dart';
import '../../../../core/design/components/ledgr_buttons.dart';
import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/components/ledgr_pill.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/money/pkr_format.dart';
import '../../../../core/privacy/private_text.dart';
import '../../../../core/time/clock.dart';
import '../../data/contact_model.dart';
import '../../data/ledger_entry_model.dart';

class ContactCardData {
  const ContactCardData({
    required this.contact,
    required this.entry,
    required this.now,
  });

  final Contact contact;
  final LedgerEntry entry;
  final DateTime now;

  String get dueLabel {
    final due = entry.dueDate;
    if (due == null) return _ago(entry.createdAt, now);
    final diff = due.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 30) return '$diff days';
    return 'Next mo.';
  }

  static String _ago(DateTime past, DateTime now) {
    final diff = now.difference(past);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'Just now';
  }
}

class ContactCard extends StatelessWidget {
  const ContactCard({
    required this.data,
    required this.onSettle,
    required this.onSecondary,
    super.key,
  });

  final ContactCardData data;
  final VoidCallback onSettle;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final entry = data.entry;
    final lent = entry.isLent;
    final color = lent ? LedgrColors.pos : LedgrColors.neg;
    final dueColor = data.dueLabel == 'Overdue'
        ? LedgrColors.neg
        : data.dueLabel == 'Today'
            ? LedgrColors.lime
            : LedgrColors.textMute;

    return LedgrCard(
      padding: 14,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LedgrAvatar(name: data.contact.name, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    lent ? const LedgrPill.lent() : const LedgrPill.borrowed(),
                    const SizedBox(height: 4),
                    Text(
                      data.contact.name,
                      style: LedgrType.listTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (entry.note != null && entry.note!.isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              entry.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LedgrType.sans(
                                fontSize: 11.5,
                                color: LedgrColors.textDim,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 2,
                            height: 2,
                            decoration: const BoxDecoration(
                              color: LedgrColors.textFaint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          data.dueLabel,
                          style: LedgrType.sans(
                            fontSize: 11.5,
                            color: dueColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PrivateText.digits(
                    PkrFormat.fromMinor(
                      entry.amountMinorUnits,
                      includeSymbol: false,
                    ),
                    style: LedgrType.amountMono(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.currencyCode,
                    style: LedgrType.sans(
                      fontSize: 9.5,
                      color: LedgrColors.textMute,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LedgrInlineAction(
                  label: 'Settle',
                  icon: Icons.check_rounded,
                  onPressed: onSettle,
                  emphasised: lent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LedgrInlineAction(
                  label: lent ? 'Remind' : 'Pay',
                  icon: lent
                      ? Icons.refresh_rounded
                      : Icons.payments_outlined,
                  onPressed: onSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Convenience hook so screens can access the current clock without re-
/// importing it everywhere they construct [ContactCardData].
DateTime nowFromClock(Clock clock) => clock.now();
