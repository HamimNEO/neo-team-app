import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../team/data/employee_store.dart';
import '../../domain/models/visit.dart';

class VisitCardItem extends StatelessWidget {
  final Visit visit;
  final VoidCallback onTap;

  const VisitCardItem({
    super.key,
    required this.visit,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'arrived':
        return const Color(0xFFAF52DE);
      case 'in_progress':
      case 'in progress':
      case 'journey':
        return const Color(0xFFF59E0B);
      case 'report due':
      case 'needs report':
      case 'report':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return const Color(0xFF8E8E93);
      case 'scheduled':
      default:
        return AppColors.brandLight;
    }
  }

  String _cleanTiming() {
    final d = visit.dateText.trim();
    final t = visit.timeText.trim();
    if (d.isEmpty && t.isEmpty) return 'Time not set';
    if (d == 'Not scheduled' || t == 'Not scheduled') return 'Not scheduled';
    if (d.isNotEmpty && t.isNotEmpty) {
      return '$d · $t';
    }
    return d.isNotEmpty ? d : t;
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final statusColor = _getStatusColor(visit.status);
    final currentEmp = EmployeeStore.instance.currentEmployee;
    final isAssignedToMe =
        visit.assigneeName.toLowerCase() == currentEmp.name.toLowerCase();
    final isUnassigned = visit.assigneeName.toLowerCase() == 'unassigned' ||
        visit.assigneeName.trim().isEmpty;

    final timing = _cleanTiming();
    final hasValidLocation = visit.location.trim().isNotEmpty &&
        visit.location.trim().toLowerCase() !=
            visit.leadName.trim().toLowerCase();

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: nec.separator.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.clock_fill,
                          size: 11.5,
                          color: AppColors.brandLight,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          timing,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          visit.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                visit.leadName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: nec.textPrimary,
                  height: 1.25,
                ),
              ),
              if (visit.purpose.trim().isNotEmpty &&
                  visit.purpose.trim().toLowerCase() !=
                      visit.leadName.trim().toLowerCase()) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: nec.separator.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    visit.purpose,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: nec.textSecondary,
                    ),
                  ),
                ),
              ],
              if (hasValidLocation) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.placemark_fill,
                      size: 13,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        visit.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: nec.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: nec.separator.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUnassigned)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: nec.separator.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.question,
                              size: 12,
                              color: nec.textTertiary,
                            ),
                          ),
                        )
                      else
                        NecAvatar(
                          initials: visit.assigneeInitials,
                          size: 22,
                        ),
                      const SizedBox(width: 7),
                      Text(
                        isUnassigned ? 'Unassigned' : visit.assigneeName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color:
                              isUnassigned ? nec.textTertiary : nec.textPrimary,
                        ),
                      ),
                      if (isAssignedToMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: nec.brand,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 12,
                        color: nec.brand,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
