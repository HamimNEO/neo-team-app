import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuditHighBadge extends StatelessWidget {
  const AuditHighBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Text(
          'HIGH',
          style: TextStyle(
            fontSize: 10,
            height: 1,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
      );
}
