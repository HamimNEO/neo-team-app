import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FormPickerSheet extends StatelessWidget {
  final String label;
  final List<String> options;

  const FormPickerSheet({
    super.key,
    required this.label,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x59787880),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: nec.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 0.5, color: nec.separator),
          ...options.map(
            (option) => ListTile(
              title: Text(option, style: TextStyle(color: nec.textPrimary)),
              onTap: () => Navigator.pop(context, option),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
