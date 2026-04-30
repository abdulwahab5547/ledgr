import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/ledgr_buttons.dart';
import '../../../../core/design/components/ledgr_segmented.dart';
import '../../../../core/design/components/ledgr_sheet.dart';
import '../../../../core/design/components/ledgr_text_field.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/haptics/haptics.dart';
import '../../../../core/money/money.dart';
import '../../data/expense_category.dart';
import '../../data/recurring_expense_model.dart';
import '../../data/recurring_expense_repository.dart';
import '../../domain/keyword_categorizer.dart';

class RecurringFormSheet extends ConsumerStatefulWidget {
  const RecurringFormSheet({super.key, this.existing});

  final RecurringExpense? existing;

  static Future<void> show(BuildContext context, {RecurringExpense? existing}) {
    return LedgrSheet.show<void>(
      context,
      builder: (_) => RecurringFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<RecurringFormSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _amount;
  late Cadence _cadence;
  late DateTime _anchor;
  late ExpenseCategory _category;
  late String _currency;
  bool _userPickedCategory = false;

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
    _cadence = e?.cadence ?? Cadence.monthly;
    _anchor = e?.anchorDate ?? DateTime.now();
    _category = e?.category ?? ExpenseCategory.other;
    _currency = e?.currencyCode ?? 'PKR';
    _userPickedCategory = _isEdit;
    _label.addListener(_maybeSuggestCategory);
  }

  void _maybeSuggestCategory() {
    if (_userPickedCategory) return;
    final guess = const KeywordCategorizer().categorize(_label.text);
    if (guess != _category) setState(() => _category = guess);
  }

  @override
  void dispose() {
    _label.removeListener(_maybeSuggestCategory);
    _label.dispose();
    _amount.dispose();
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
            _isEdit ? 'Edit recurring' : 'New recurring',
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
          Text('CADENCE', style: LedgrType.eyebrow(fontSize: 11)),
          const SizedBox(height: 6),
          LedgrSegmented<Cadence>(
            segments: const [
              LedgrSegment(value: Cadence.weekly, label: 'Weekly'),
              LedgrSegment(value: Cadence.monthly, label: 'Monthly'),
              LedgrSegment(value: Cadence.yearly, label: 'Yearly'),
            ],
            value: _cadence,
            onChanged: (v) => setState(() => _cadence = v),
          ),
          const SizedBox(height: 12),
          _AnchorDatePicker(
            value: _anchor,
            onChanged: (d) => setState(() => _anchor = d),
          ),
          const SizedBox(height: 12),
          Text('CATEGORY', style: LedgrType.eyebrow(fontSize: 11)),
          const SizedBox(height: 8),
          _CategoryPicker(
            value: _category,
            onChanged: (v) => setState(() {
              _category = v;
              _userPickedCategory = true;
            }),
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
    final repo = ref.read(recurringExpenseRepositoryProvider);
    final money = Money.fromMajor(
      double.parse(_amount.text),
      currencyCode: _currency,
    );
    if (_isEdit) {
      final existing = widget.existing!;
      existing
        ..label = _label.text.trim()
        ..amountMinorUnits = money.minorUnits
        ..currencyCode = _currency
        ..cadence = _cadence
        ..anchorDate = _anchor
        ..category = _category;
      await repo.update(existing);
    } else {
      await repo.create(
        label: _label.text.trim(),
        amountMinorUnits: money.minorUnits,
        currencyCode: _currency,
        cadence: _cadence,
        anchorDate: _anchor,
        category: _category,
      );
    }
    await Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }
}

class _AnchorDatePicker extends StatelessWidget {
  const _AnchorDatePicker({required this.value, required this.onChanged});

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
          firstDate: DateTime(now.year - 5),
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
            const Icon(
              Icons.event_repeat_outlined,
              size: 16,
              color: LedgrColors.textDim,
            ),
            const SizedBox(width: 8),
            Text(
              'Anchor: $label',
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

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.value, required this.onChanged});

  final ExpenseCategory value;
  final ValueChanged<ExpenseCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in ExpenseCategory.values)
          GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: value == c
                    ? const Color(0x1FC9FF5E)
                    : const Color(0x0FFFFFFF),
                border: Border.all(
                  color: value == c ? LedgrColors.lime : LedgrColors.hairline2,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c.label,
                    style: LedgrType.sans(
                      fontSize: 13,
                      color: value == c
                          ? LedgrColors.lime
                          : LedgrColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
