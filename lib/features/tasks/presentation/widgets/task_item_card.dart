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
  final String? status;
  final ValueChanged<bool?>? onToggle;
  final ValueChanged<String>? onStatusChange;
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
    this.status,
    this.onToggle,
    this.onStatusChange,
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
                      if (relatedText?.isNotEmpty == true) ...[
                        Icon(
                          CupertinoIcons.person_2,
                          size: 13,
                          color: nec.brand,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            relatedText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: nec.brand,
                            ),
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(' · ',
                              style: TextStyle(
                                  fontSize: 12.5, color: nec.textTertiary)),
                      ],
                      if (subtitle.isNotEmpty)
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5, color: nec.textTertiary),
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
                      Expanded(
                        child: Text(
                          assigneeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: nec.textSecondary,
                          ),
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: 8),
                        if (status == 'to_do' && onStatusChange != null)
                          InkWell(
                            onTap: () => onStatusChange!('in_progress'),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5856D6)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF5856D6)
                                      .withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.play_fill,
                                      size: 9, color: Color(0xFF5856D6)),
                                  SizedBox(width: 4),
                                  Text(
                                    'In Progress',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5856D6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (status == 'in_progress' &&
                            onStatusChange != null)
                          InkWell(
                            onTap: () => onStatusChange!('to_do'),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9500)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFF9500)
                                      .withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.flame_fill,
                                      size: 10, color: Color(0xFFFF9500)),
                                  SizedBox(width: 4),
                                  Text(
                                    'In Progress',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF9500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.checkmark_alt,
                                    size: 11, color: AppColors.success),
                                SizedBox(width: 3),
                                Text(
                                  'Done',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
