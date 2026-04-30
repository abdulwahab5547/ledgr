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
import '../../../core/money/pkr_format.dart';
import '../data/account_model.dart';
import '../data/account_repository.dart';

class QuickAdjustPad extends ConsumerStatefulWidget {
  const QuickAdjustPad({super.key, required this.account});

  final Account account;

  static Future<void> show(BuildContext context, {required Account account}) {
    return LedgrSheet.show<void>(
      context,
      builder: (_) => QuickAdjustPad(account: account),
    );
  }

  @override
  ConsumerState<QuickAdjustPad> createState() => _QuickAdjustPadState();
}

class _QuickAdjustPadState extends ConsumerState<QuickAdjustPad> {
  late final TextEditingController _controller;
  final _form = GlobalKey<FormState>();
  String? _note;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.account.balance.major.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.account.currencyCode == 'PKR'
        ? PkrFormat.money(widget.account.balance)
        : widget.account.balance.format();
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Quick Adjust ',
                  style: LedgrType.editorialItalic(),
                ),
                TextSpan(
                  text: '· ${widget.account.label}',
                  style: LedgrType.serif(fontSize: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Current: $currentText',
            style: LedgrType.bodySmall(color: LedgrColors.textMute),
          ),
          const SizedBox(height: 18),
          LedgrTextField(
            controller: _controller,
            label: 'New balance',
            prefix: '${widget.account.currencyCode} ',
            useMonoText: true,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          LedgrTextField(
            label: 'Note (optional)',
            onChanged: (v) => _note = v.trim().isEmpty ? null : v.trim(),
          ),
          const SizedBox(height: 24),
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
                  label: 'Save',
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
    final money = Money.fromMajor(
      double.parse(_controller.text),
      currencyCode: widget.account.currencyCode,
    );
    await repo.setBalance(
      accountId: widget.account.id,
      newBalanceMinorUnits: money.minorUnits,
      note: _note,
    );
    await Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }
}
