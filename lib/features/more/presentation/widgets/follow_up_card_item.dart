import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/follow_up.dart';

class FollowUpCardItem extends StatelessWidget {
  final FollowUp item;
  final VoidCallback onTap;
  final ValueChanged<bool>? onToggleComplete;

  const FollowUpCardItem({
    super.key,
    required this.item,
    required this.onTap,
    this.onToggleComplete,
  });

  IconData _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'whatsapp':
        return CupertinoIcons.chat_bubble_fill;
      case 'email':
        return CupertinoIcons.mail_solid;
      case 'meeting':
        return CupertinoIcons.person_2_fill;
      case 'call':
      default:
        return CupertinoIcons.phone_fill;
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'email':
        return AppColors.brandLight;
      case 'meeting':
        return AppColors.warning;
      case 'call':
      default:
        return AppColors.brandLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLate = item.lateHours != null;
    final isCompleted = item.isCompleted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompleted) ...[
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 14),
            ] else if (isLate) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LATE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.lateHours!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.timeText.split(' ')[0],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: nec.textPrimary,
                    ),
                  ),
                  if (item.timeText.contains(' '))
                    Text(
                      item.timeText.split(' ')[1],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: nec.textTertiary,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.leadName,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.purpose,
                    style: TextStyle(
                      fontSize: 13,
                      color: nec.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _getMethodIcon(item.method),
                        size: 13,
                        color: _getMethodColor(item.method),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.method} · ${item.assigneeName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                      if (item.isAutoSmsEnabled) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6355F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.chat_bubble_text_fill,
                                  size: 9, color: Color(0xFF6355F6)),
                              SizedBox(width: 3),
                              Text(
                                'Auto SMS',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6355F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.resultTag != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.resultTag == 'Interested'
                            ? AppColors.success.withValues(alpha: 0.18)
                            : AppColors.warning.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.resultTag!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.resultTag == 'Interested'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isCompleted)
              GestureDetector(
                onTap: () {
                  if (onToggleComplete != null) {
                    onToggleComplete!(true);
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C2C22)
                        : AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
