import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ledgr_colors.dart';
import '../ledgr_radii.dart';
import '../ledgr_typography.dart';

/// Themed input field — flat translucent surface, hairline border, lime
/// focus stroke. Used across all sheets.
class LedgrTextField extends StatelessWidget {
  const LedgrTextField({
    this.controller,
    this.initialValue,
    this.label,
    this.helper,
    this.prefix,
    this.hint,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.useMonoText = false,
    super.key,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? helper;
  final String? prefix;
  final String? hint;
  final bool autofocus;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool useMonoText;

  @override
  Widget build(BuildContext context) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LedgrRadii.cardInner),
      borderSide:
          const BorderSide(color: LedgrColors.hairline2, width: 0.5),
    );
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      autofocus: autofocus,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      cursorColor: LedgrColors.lime,
      style: useMonoText
          ? LedgrType.mono(fontSize: 14)
          : LedgrType.sans(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        prefixText: prefix,
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        labelStyle: LedgrType.sans(fontSize: 12, color: LedgrColors.textDim),
        helperStyle: LedgrType.sans(fontSize: 11, color: LedgrColors.textMute),
        prefixStyle: LedgrType.mono(fontSize: 13, color: LedgrColors.textDim),
        hintStyle: LedgrType.sans(fontSize: 14, color: LedgrColors.textFaint),
        border: base,
        enabledBorder: base,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LedgrRadii.cardInner),
          borderSide: const BorderSide(color: LedgrColors.lime, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
