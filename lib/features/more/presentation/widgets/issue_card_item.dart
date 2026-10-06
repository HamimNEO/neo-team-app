import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';

class IssueCardItem extends StatelessWidget {
  final String issueKey;
  final String title;
  final String subtitle;
  final String priority;
  final Color priorityColor;
  final String status;
  final Color statusColor;
  final String? assigneeInitials;
  final String? assigneeName;
  final String date;
  final bool hasRedDot;
  final VoidCallback onTap;

  const IssueCardItem({
    super.key,
    required this.issueKey,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.priorityColor,
    required this.status,
    required this.statusColor,
    this.assigneeInitials,
    this.assigneeName,
    required this.date,
    this.hasRedDot = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isUnassigned = assigneeName == null || assigneeName == 'Unassigned';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (hasRedDot) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      issueKey,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: nec.textTertiary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: nec.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (!isUnassigned) ...[
                      NecAvatar(
                        initials: (assigneeInitials != null &&
                                assigneeInitials!.isNotEmpty)
                            ? assigneeInitials!
                            : (assigneeName != null && assigneeName!.isNotEmpty
                                ? assigneeName!.substring(0, 1).toUpperCase()
                                : 'U'),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        assigneeName!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: nec.textSecondary,
                        ),
                      ),
                    ] else
                      const Text(
                        'Unassigned',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                  ],
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: nec.textTertiary,
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
