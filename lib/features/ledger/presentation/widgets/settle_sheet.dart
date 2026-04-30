import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/ledgr_buttons.dart';
import '../../../../core/design/components/ledgr_sheet.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_radii.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/haptics/haptics.dart';
import '../../../../core/money/pkr_format.dart';
import '../../../vault/data/account_model.dart';
import '../../../vault/domain/vault_providers.dart';
import '../../data/contact_model.dart';
import '../../data/ledger_entry_model.dart';
import '../../domain/settlement_service.dart';

/// Confirm settlement against a chosen Vault account. Reuses the same
/// pipeline (`AccountRepository.adjustBalance`) so the audit trail stays
/// the single source of truth.
class SettleSheet extends ConsumerStatefulWidget {
  const SettleSheet({
    required this.entry,
    required this.contact,
    super.key,
  });

  final LedgerEntry entry;
  final Contact contact;

  static Future<void> show(
    BuildContext context, {
    required LedgerEntry entry,
    required Contact contact,
  }) {
    return LedgrSheet.show<void>(
      context,
      builder: (_) => SettleSheet(entry: entry, contact: contact),
    );
  }

  @override
  ConsumerState<SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends ConsumerState<SettleSheet> {
  String? _selectedAccountId;
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? const [];
    final compatible = accounts
        .where((a) => a.currencyCode == widget.entry.currencyCode)
        .toList(growable: false);
    final amount = PkrFormat.fromMinor(widget.entry.amountMinorUnits);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Settle with ',
                style: LedgrType.editorialItalic(),
              ),
              TextSpan(
                text: '${widget.contact.name.split(' ').first}?',
                style: LedgrType.serif(fontSize: 26),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: LedgrType.sans(
              fontSize: 13.5,
              color: LedgrColors.textDim,
              height: 1.45,
            ),
            children: [
              const TextSpan(text: 'Mark '),
              TextSpan(
                text: amount,
                style: LedgrType.mono(
                  fontSize: 13.5,
                  color: LedgrColors.text,
                ),
              ),
              if (widget.entry.note != null &&
                  widget.entry.note!.isNotEmpty) ...[
                const TextSpan(text: ' for '),
                TextSpan(
                  text: widget.entry.note!,
                  style: LedgrType.sans(
                    fontSize: 13.5,
                    color: LedgrColors.text,
                  ),
                ),
              ],
              const TextSpan(text: ' as fully paid. This cannot be undone.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'POST TO ACCOUNT',
          style: LedgrType.eyebrow(
            fontSize: 11,
            color: LedgrColors.textMute,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (compatible.isEmpty)
          Text(
            'No ${widget.entry.currencyCode} accounts. Add one in the Vault first.',
            style:
                LedgrType.sans(fontSize: 13, color: LedgrColors.neg),
          )
        else
          ...compatible.map(
            (a) => _AccountChoice(
              account: a,
              selected: _selectedAccountId == a.id,
              onTap: () => setState(() => _selectedAccountId = a.id),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: LedgrType.sans(fontSize: 12, color: LedgrColors.neg),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: LedgrSecondaryButton(
                label: 'Cancel',
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 14,
              child: LedgrPrimaryButton(
                label: _busy ? 'Settling…' : 'Confirm settlement',
                icon: Icons.check_rounded,
                onPressed: _busy ||
                        _selectedAccountId == null ||
                        compatible.isEmpty
                    ? null
                    : _confirm,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    if (_selectedAccountId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(settlementServiceProvider).settle(
            entryId: widget.entry.id,
            accountId: _selectedAccountId!,
          );
      await Haptics.success();
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
      await Haptics.warn();
    }
  }
}

class _AccountChoice extends StatelessWidget {
  const _AccountChoice({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final Account account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(LedgrRadii.cardInner),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LedgrRadii.cardInner),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0x1FC9FF5E)
                  : const Color(0x0FFFFFFF),
              border: Border.all(
                color: selected
                    ? LedgrColors.lime
                    : LedgrColors.hairline2,
                width: 0.5,
              ),
              borderRadius:
                  BorderRadius.circular(LedgrRadii.cardInner),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.label, style: LedgrType.listTitle()),
                      const SizedBox(height: 2),
                      Text(
                        account.currencyCode,
                        style: LedgrType.mono(
                          fontSize: 11,
                          color: LedgrColors.textMute,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  PkrFormat.money(account.balance),
                  style: LedgrType.amountMono(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
