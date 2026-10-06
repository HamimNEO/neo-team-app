import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileWorkTab extends StatelessWidget {
  const ProfileWorkTab({super.key});

  void _onItemTap(BuildContext context, String route) {
    if (route == '/leads' || route == '/tasks') {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final items = [
      {
        'title': 'My Leads',
        'subtitle': 'Active assignments',
        'count': '4',
        'color': AppColors.brandLight,
        'icon': CupertinoIcons.person_2,
        'route': '/leads',
      },
      {
        'title': 'Follow-ups',
        'subtitle': '0 overdue',
        'count': '0',
        'color': AppColors.warning,
        'icon': CupertinoIcons.arrow_turn_down_left,
        'route': '/follow-ups',
      },
      {
        'title': 'Visits',
        'subtitle': 'Scheduled',
        'count': '0',
        'color': AppColors.leadVisit,
        'icon': CupertinoIcons.house_fill,
        'route': '/visits',
      },
      {
        'title': 'Tasks',
        'subtitle': '2 due today',
        'count': '3',
        'color': AppColors.leadContacted,
        'icon': CupertinoIcons.checkmark_rectangle,
        'route': '/tasks',
      },
      {
        'title': 'Issues',
        'subtitle': '0 high priority',
        'count': '0',
        'color': AppColors.error,
        'icon': CupertinoIcons.exclamationmark_octagon,
        'route': '/issues',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final color = item['color'] as Color;
            final isLast = index == items.length - 1;

            return Column(
              children: [
                InkWell(
                  onTap: () => _onItemTap(context, item['route'] as String),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: color,
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
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nec.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item['count'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: nec.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: nec.separator.withValues(alpha: 0.3),
                    indent: 68,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
