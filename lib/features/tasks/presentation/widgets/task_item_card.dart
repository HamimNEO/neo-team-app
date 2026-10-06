import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';

class TaskItemCard extends StatelessWidget {
  final String title;
  final String? relatedText;
  final String? relatedRoute;
  final String subtitle;
  final String priority;
  final Color priorityColor;
  final String assigneeInitials;
  final String assigneeName;
  final bool isCompleted;
  final ValueChanged<bool?>? onToggle;
  final VoidCallback onTap;

  const TaskItemCard({
    super.key,
    required this.title,
    this.relatedText,
    this.relatedRoute,
    required this.subtitle,
    required this.priority,
    required this.priorityColor,
    required this.assigneeInitials,
    required this.assigneeName,
    this.isCompleted = false,
    this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (onToggle != null) {
                  onToggle!(!isCompleted);
                }
              },
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.success
                        : nec.textTertiary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        CupertinoIcons.checkmark,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? nec.textTertiary : nec.textPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: nec.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (relatedText != null) ...[
                        Icon(
                          CupertinoIcons.person_2,
                          size: 13,
                          color: nec.brand,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          relatedText!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: nec.brand,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: nec.textTertiary,
                          ),
                        ),
                      ],
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: priorityColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      NecAvatar(
                        initials: assigneeInitials,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        assigneeName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: nec.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
