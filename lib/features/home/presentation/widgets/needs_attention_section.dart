import 'dashboard_rows.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class NeedsAttentionSection extends StatelessWidget {
  final bool staff;

  const NeedsAttentionSection({super.key, this.staff = false});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final items = DashboardRows.attention(staff: staff);
    if (items.isEmpty) {
      return const SectionEmptyCard(
        icon: CupertinoIcons.shield_fill,
        title: 'You’re all caught up',
        subtitle: 'No pending items need your attention.',
      );
    }

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.map((item) {
          final isOverdue = item['isOverdue'] as bool;
          return InkWell(
            onTap: () => context.push(item['route'] as String),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color:
                          isOverdue ? AppColors.warning : AppColors.brandLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue
                                ? AppColors.warning
                                : nec.textTertiary,
                            fontWeight:
                                isOverdue ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
