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
import '../../data/contact_model.dart';
import '../../data/contact_repository.dart';
import '../../data/ledger_entry_model.dart';
import '../../data/ledger_repository.dart';
import '../../domain/social_balances_provider.dart';

/// Sheet for adding a new IOU. Picks/creates a contact, sets direction,
/// amount, optional note + due date.
class EntryFormSheet extends ConsumerStatefulWidget {
  const EntryFormSheet({super.key});

  static Future<void> show(BuildContext context) {
    return LedgrSheet.show<void>(
      context,
      builder: (_) => const EntryFormSheet(),
    );
  }

  @override
  ConsumerState<EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends ConsumerState<EntryFormSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _newContactName = TextEditingController();
  LedgerDirection _direction = LedgerDirection.lent;
  String _currency = 'PKR';
  Contact? _selectedContact;
  bool _addingNewContact = false;
  DateTime? _due;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _newContactName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsStreamProvider).valueOrNull ?? const [];
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New entry', style: LedgrType.serif(fontSize: 26)),
          const SizedBox(height: 18),
          LedgrSegmented<LedgerDirection>(
            segments: const [
              LedgrSegment(value: LedgerDirection.lent, label: 'Lent'),
              LedgrSegment(value: LedgerDirection.borrowed, label: 'Borrowed'),
            ],
            value: _direction,
            onChanged: (v) => setState(() => _direction = v),
          ),
          const SizedBox(height: 12),
          if (!_addingNewContact)
            _ContactPicker(
              contacts: contacts,
              selected: _selectedContact,
              onSelected: (c) => setState(() => _selectedContact = c),
              onAddNew: () => setState(() {
                _addingNewContact = true;
                _selectedContact = null;
              }),
            )
          else
            Row(
              children: [
                Expanded(
                  child: LedgrTextField(
                    controller: _newContactName,
                    label: 'New contact',
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => _addingNewContact &&
                            (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() {
                    _addingNewContact = false;
                    _newContactName.clear();
                  }),
                  icon: const Icon(
                    Icons.close,
                    color: LedgrColors.textDim,
                  ),
                ),
              ],
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
            controller: _note,
            label: 'Note (optional)',
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          _DuePicker(
            due: _due,
            onChanged: (d) => setState(() => _due = d),
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
    if (!_addingNewContact && _selectedContact == null) {
      setState(() => _error = 'Pick a contact');
      return;
    }
    setState(() => _error = null);
    final money = Money.fromMajor(
      double.parse(_amount.text),
      currencyCode: _currency,
    );
    final contactRepo = ref.read(contactRepositoryProvider);
    final contact = _addingNewContact
        ? await contactRepo.create(name: _newContactName.text.trim())
        : _selectedContact!;
    await ref.read(ledgerRepositoryProvider).create(
          contactId: contact.id,
          direction: _direction,
          amountMinorUnits: money.minorUnits,
          currencyCode: _currency,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          dueDate: _due,
        );
    await Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }
}

class _ContactPicker extends StatelessWidget {
  const _ContactPicker({
    required this.contacts,
    required this.selected,
    required this.onSelected,
    required this.onAddNew,
  });

  final List<Contact> contacts;
  final Contact? selected;
  final ValueChanged<Contact> onSelected;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return GestureDetector(
        onTap: onAddNew,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            border:
                Border.all(color: LedgrColors.hairline2, width: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                size: 16,
                color: LedgrColors.textDim,
              ),
              const SizedBox(width: 8),
              Text(
                'Add your first contact',
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in contacts)
          GestureDetector(
            onTap: () => onSelected(c),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected?.id == c.id
                    ? const Color(0x1FC9FF5E)
                    : const Color(0x0FFFFFFF),
                border: Border.all(
                  color: selected?.id == c.id
                      ? LedgrColors.lime
                      : LedgrColors.hairline2,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                c.name,
                style: LedgrType.sans(
                  fontSize: 13,
                  color: selected?.id == c.id
                      ? LedgrColors.lime
                      : LedgrColors.textDim,
                ),
              ),
            ),
          ),
        GestureDetector(
          onTap: onAddNew,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: LedgrColors.hairline2,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 14, color: LedgrColors.textDim),
                const SizedBox(width: 4),
                Text(
                  'New',
                  style: LedgrType.sans(
                    fontSize: 13,
                    color: LedgrColors.textDim,
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

class _DuePicker extends StatelessWidget {
  const _DuePicker({required this.due, required this.onChanged});

  final DateTime? due;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = due == null
        ? 'No due date'
        : '${due!.day}/${due!.month}/${due!.year}';
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: due ?? now.add(const Duration(days: 7)),
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
              onChanged(picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                border:
                    Border.all(color: LedgrColors.hairline2, width: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: LedgrColors.textDim,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due: $label',
                    style: LedgrType.sans(
                      fontSize: 13,
                      color: LedgrColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (due != null)
          IconButton(
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close, color: LedgrColors.textDim, size: 18),
          ),
      ],
    );
  }
}
