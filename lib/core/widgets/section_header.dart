import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionTitle;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionTitle,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: nec.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        if (actionTitle != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionTitle!,
              style: TextStyle(
                fontSize: 13,
                color: nec.brand,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
