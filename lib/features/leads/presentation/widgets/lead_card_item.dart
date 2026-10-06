import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';

class LeadCardItem extends StatelessWidget {
  final String company;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String? scheduleNote;
  final bool isOverdue;
  final String assigneeInitials;
  final String assigneeName;
  final VoidCallback onTap;

  const LeadCardItem({
    super.key,
    required this.company,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.scheduleNote,
    this.isOverdue = false,
    required this.assigneeInitials,
    required this.assigneeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    company,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: nec.textTertiary,
              ),
            ),
            if (scheduleNote != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    isOverdue
                        ? CupertinoIcons.exclamationmark_triangle
                        : CupertinoIcons.clock,
                    size: 14,
                    color: isOverdue ? AppColors.error : nec.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    scheduleNote!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                      color: isOverdue ? AppColors.error : nec.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (assigneeInitials != '??')
                  NecAvatar(
                    initials: assigneeInitials,
                    size: 22,
                  )
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: nec.textTertiary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.person,
                      size: 12,
                      color: nec.textTertiary,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  assigneeName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: nec.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
