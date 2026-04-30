import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/ledgr_buttons.dart';
import '../../../core/design/components/ledgr_sheet.dart';
import '../../../core/design/components/ledgr_text_field.dart';
import '../../../core/design/ledgr_colors.dart';
import '../../../core/design/ledgr_typography.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/money/money.dart';
import '../data/account_model.dart';
import '../data/account_repository.dart';

class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.existing});

  final Account? existing;

  static Future<void> show(BuildContext context, {Account? existing}) {
    return LedgrSheet.show<void>(
      context,
      builder: (_) => AccountFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  late final TextEditingController _label;
  late final TextEditingController _balance;
  late AccountType _type;
  String _currency = 'PKR';
  final _form = GlobalKey<FormState>();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _label = TextEditingController(text: existing?.label ?? '');
    _balance = TextEditingController(
      text: existing == null
          ? ''
          : existing.balance.major.toStringAsFixed(2),
    );
    _type = existing?.type ?? AccountType.bank;
    _currency = existing?.currencyCode ?? 'PKR';
  }

  @override
  void dispose() {
    _label.dispose();
    _balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEdit ? 'Edit account' : 'New account',
            style: LedgrType.serif(fontSize: 26),
          ),
          const SizedBox(height: 18),
          LedgrTextField(
            controller: _label,
            label: 'Label',
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _TypePicker(
            value: _type,
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 12),
          LedgrTextField(
            controller: _balance,
            label: _isEdit ? 'Balance' : 'Opening balance',
            prefix: '$_currency ',
            useMonoText: true,
            helper: _isEdit
                ? 'Editing here does not adjust balance — long-press the row for Quick Adjust.'
                : null,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
            ],
            enabled: !_isEdit,
            validator: (v) {
              if (_isEdit) return null;
              if (v == null || v.trim().isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          LedgrTextField(
            initialValue: _currency,
            label: 'Currency code',
            hint: 'PKR',
            useMonoText: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) => _currency = v.trim().toUpperCase(),
            validator: (v) {
              if (v == null || v.trim().length != 3) {
                return 'Use a 3-letter ISO code';
              }
              return null;
            },
          ),
          if (_isEdit) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _archive,
                icon: const Icon(
                  Icons.archive_outlined,
                  size: 16,
                  color: LedgrColors.textDim,
                ),
                label: Text(
                  'Archive account',
                  style: LedgrType.sans(
                    fontSize: 13,
                    color: LedgrColors.textDim,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: LedgrSecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LedgrPrimaryButton(
                  label: _isEdit ? 'Save' : 'Create',
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final repo = ref.read(accountRepositoryProvider);
    final label = _label.text.trim();
    if (_isEdit) {
      await repo.rename(widget.existing!.id, label);
    } else {
      final money = Money.fromMajor(
        double.parse(_balance.text),
        currencyCode: _currency,
      );
      await repo.create(
        label: label,
        type: _type,
        openingBalanceMinorUnits: money.minorUnits,
        currencyCode: _currency,
      );
    }
    await Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _archive() async {
    final repo = ref.read(accountRepositoryProvider);
    await repo.archive(widget.existing!.id);
    await Haptics.warn();
    if (mounted) Navigator.of(context).pop();
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.value, required this.onChanged});

  final AccountType value;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in AccountType.values)
          _Chip(
            label: _label(t),
            selected: t == value,
            onTap: () => onChanged(t),
          ),
      ],
    );
  }

  String _label(AccountType t) => switch (t) {
        AccountType.bank => 'Bank',
        AccountType.wallet => 'Wallet',
        AccountType.cash => 'Cash',
        AccountType.other => 'Other',
      };
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0x1FC9FF5E)
              : const Color(0x0FFFFFFF),
          border: Border.all(
            color: selected ? LedgrColors.lime : LedgrColors.hairline2,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: LedgrType.sans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? LedgrColors.lime : LedgrColors.textDim,
          ),
        ),
      ),
    );
  }
}
