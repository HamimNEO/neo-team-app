import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class EmployeeFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const EmployeeFormField(
      {super.key,
      required this.label,
      required this.controller,
      this.hint,
      this.validator,
      this.keyboardType = TextInputType.text,
      this.readOnly = false,
      this.onTap,
      this.maxLines = 1,
      this.inputFormatters});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: nec.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(color: nec.textPrimary, fontSize: 15),
          decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: nec.bg,
              hintStyle: TextStyle(color: nec.textTertiary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: nec.separator)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: nec.brand, width: 1.5))),
        ),
      ]),
    );
  }
}

String? requiredEmployeeField(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

String? employeeEmailValidator(String? value) {
  if (requiredEmployeeField(value) != null) return 'Enter a work email.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? employeePhoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'[\s()+\-]'), '');
  return RegExp(r'^\d{7,15}$').hasMatch(digits)
      ? null
      : 'Enter a valid phone number.';
}
