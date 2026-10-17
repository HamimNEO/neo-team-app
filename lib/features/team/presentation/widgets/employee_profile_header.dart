import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
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
    final isActive = employee.status.toLowerCase() == 'active';
    final description =
        '${employee.department.split(' · ').first} · ${employee.team}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C7BE),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NEC TEAM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: nec.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: nec.brand.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: NecAvatar(
                      initials: employee.avatarInitials,
                      photoBase64: employee.photoBase64,
                      photoUrl: employee.photoUrl,
                      assetPath: employee.avatarAsset,
                      backgroundColor: nec.brand,
                      size: 128,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isActive
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: nec.bg, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      employee.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: nec.textPrimary,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (employee.designation.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: nec.brand.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              employee.designation,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: nec.brand,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: employee.isProbation
                                ? (employee.isProbationCompleted
                                    ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.12)
                                    : const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.14))
                                : const Color(0xFF10B981)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                employee.isProbation
                                    ? (employee.isProbationCompleted
                                        ? CupertinoIcons.checkmark_shield_fill
                                        : CupertinoIcons.timer)
                                    : CupertinoIcons.checkmark_shield_fill,
                                size: 12,
                                color: employee.isProbation
                                    ? (employee.isProbationCompleted
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFD97706))
                                    : const Color(0xFF059669),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                employee.isProbation
                                    ? (employee.isProbationCompleted
                                        ? 'Probation Ended'
                                        : 'Probation (${employee.probationRemainingDays}d left)')
                                    : 'Permanent',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: employee.isProbation
                                      ? (employee.isProbationCompleted
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFD97706))
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (employee.displayCode.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        employee.displayCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: nec.textTertiary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Divider(
              height: 1,
              color: nec.separator.withValues(alpha: 0.35),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(
                  CupertinoIcons.briefcase_fill,
                  size: 20,
                  color: nec.brand,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPARTMENT & FUNCTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: nec.textTertiary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: nec.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      NecToast.show(
                        context,
                        message: 'Calling ${employee.phone}...',
                        type: NecToastType.success,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: nec.separator.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.phone_fill,
                            color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Call',
                          style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      employee.id == DemoSession.instance.employeeId
                          ? '/messages'
                          : '/messages/${employee.id}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nec.brand,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.chat_bubble_fill,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Message',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
