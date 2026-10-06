import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../domain/models/employee.dart';

class EmployeeProfileHeader extends StatelessWidget {
  final Employee employee;

  const EmployeeProfileHeader({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          NecAvatar(
              initials: employee.avatarInitials,
              photoBase64: employee.photoBase64,
              size: 84,
              backgroundColor: nec.brand),
          const SizedBox(height: 14),
          Text(
            employee.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: nec.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            employee.designation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: nec.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            employee.displayCode,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: nec.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  employee.status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${employee.department.split(' · ').first} · ${employee.team}',
                style: TextStyle(
                  fontSize: 13,
                  color: nec.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      NecToast.show(
                        context,
                        message: 'Calling ${employee.phone}...',
                        type: NecToastType.success,
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.phone_fill,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Call',
                    style: TextStyle(
                      fontSize: 12,
                      color: nec.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 28),
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      NecToast.show(
                        context,
                        message: 'Emailing ${employee.email}...',
                        type: NecToastType.success,
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.brandLight.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.chat_bubble_fill,
                        color: AppColors.brandLight,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 12,
                      color: nec.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
