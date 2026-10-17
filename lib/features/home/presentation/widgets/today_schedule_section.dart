import 'dashboard_rows.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class TodayScheduleSection extends StatelessWidget {
  final bool staff;

  const TodayScheduleSection({super.key, this.staff = false});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final scheduleItems = DashboardRows.today(staff: staff);
    if (scheduleItems.isEmpty) {
      return const SectionEmptyCard(
        icon: CupertinoIcons.calendar,
        title: 'Nothing scheduled today',
        subtitle: 'Your schedule is clear for today.',
      );
    }

    final lateCount =
        scheduleItems.where((item) => item['isLate'] as bool).length;
    return Column(
      children: [
        if (lateCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$lateCount ${lateCount == 1 ? 'item' : 'items'} overdue',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        Material(
          color: nec.surface,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(lateCount > 0 ? 0 : 16),
              bottom: const Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: scheduleItems.map((item) {
              final isLate = item['isLate'] as bool;
              final isVisit = (item['type'] as String).contains('Visit');

              return InkWell(
                onTap: () => context.push(item['route'] as String),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          item['time'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isLate ? AppColors.error : nec.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isVisit
                              ? AppColors.leadVisit.withValues(alpha: 0.15)
                              : AppColors.brandLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isVisit
                              ? CupertinoIcons.house_fill
                              : CupertinoIcons.phone,
                          color: isVisit
                              ? AppColors.leadVisit
                              : AppColors.brandLight,
                          size: 16,
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
                                color:
                                    isLate ? AppColors.error : nec.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['type'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
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
        ),
      ],
    );
  }
}
