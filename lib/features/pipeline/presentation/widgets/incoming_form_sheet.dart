import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/ledgr_buttons.dart';
import '../../../../core/design/components/ledgr_sheet.dart';
import '../../../../core/design/components/ledgr_text_field.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/haptics/haptics.dart';
import '../../../../core/money/money.dart';
import '../../data/incoming_payment_model.dart';
import '../../data/incoming_payment_repository.dart';

class IncomingFormSheet extends ConsumerStatefulWidget {
  const IncomingFormSheet({super.key, this.existing});

  final IncomingPayment? existing;

  static Future<void> show(BuildContext context, {IncomingPayment? existing}) {
    return LedgrSheet.show<void>(
      context,
      builder: (_) => IncomingFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<IncomingFormSheet> createState() => _IncomingFormSheetState();
}

class _IncomingFormSheetState extends ConsumerState<IncomingFormSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _amount;
  late final TextEditingController _source;
  late DateTime _expectedDate;
  late String _currency;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _amount = TextEditingController(
      text: e == null
          ? ''
          : Money(e.amountMinorUnits, currencyCode: e.currencyCode)
              .major
              .toStringAsFixed(2),
    );
    _source = TextEditingController(text: e?.source ?? '');
    _expectedDate =
        e?.expectedDate ?? DateTime.now().add(const Duration(days: 7));
    _currency = e?.currencyCode ?? 'PKR';
  }

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    _source.dispose();
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
            _isEdit ? 'Edit incoming' : 'New incoming',
            style: LedgrType.serif(fontSize: 26),
          ),
          const SizedBox(height: 18),
          LedgrTextField(
            controller: _label,
            label: 'Label',
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LedgrTextField(
                  controller: _amount,
                  label: 'Amount',
                  prefix: '$_currency ',
                  useMonoText: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a positive amount';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                child: LedgrTextField(
                  initialValue: _currency,
                  label: 'Currency',
                  useMonoText: true,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (v) =>
                      _currency = v.trim().toUpperCase(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LedgrTextField(
            controller: _source,
            label: 'Source (optional)',
            hint: 'e.g. Acme Corp',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          _ExpectedDatePicker(
            value: _expectedDate,
            onChanged: (d) => setState(() => _expectedDate = d),
          ),
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
    final repo = ref.read(incomingPaymentRepositoryProvider);
    final money = Money.fromMajor(
      double.parse(_amount.text),
      currencyCode: _currency,
    );
    final source = _source.text.trim();
    if (_isEdit) {
      final existing = widget.existing!;
      existing
        ..label = _label.text.trim()
        ..amountMinorUnits = money.minorUnits
        ..currencyCode = _currency
        ..expectedDate = _expectedDate
        ..source = source.isEmpty ? null : source;
      await repo.update(existing);
    } else {
      await repo.create(
        label: _label.text.trim(),
        amountMinorUnits: money.minorUnits,
        currencyCode: _currency,
        expectedDate: _expectedDate,
        source: source.isEmpty ? null : source,
      );
    }
    await Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }
}

class _ExpectedDatePicker extends StatelessWidget {
  const _ExpectedDatePicker({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = '${value.day}/${value.month}/${value.year}';
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: now.subtract(const Duration(days: 30)),
          lastDate: DateTime(now.year + 5),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: LedgrColors.lime,
                onPrimary: LedgrColors.bg,
                surface: Color(0xFF15161A),
                onSurface: LedgrColors.text,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          border: Border.all(color: LedgrColors.hairline2, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined,
                size: 16, color: LedgrColors.textDim,),
            const SizedBox(width: 8),
            Text(
              'Expected: $label',
              style: LedgrType.sans(
                fontSize: 13,
                color: LedgrColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
