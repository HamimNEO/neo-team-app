import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FormSectionTitle extends StatelessWidget {
  final String title;

  const FormSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: nec.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
