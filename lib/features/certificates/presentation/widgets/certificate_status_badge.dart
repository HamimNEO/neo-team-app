import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/certificate_request.dart';

class CertificateStatusBadge extends StatelessWidget {
  final CertificateStatus status;

  const CertificateStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case CertificateStatus.pending:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        break;
      case CertificateStatus.inPreparation:
        bg = const Color(0xFF0066FF).withValues(alpha: 0.15);
        fg = const Color(0xFF0066FF);
        break;
      case CertificateStatus.delivered:
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case CertificateStatus.rejected:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
