import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/account_profile.dart';

class ProfileWorkTab extends StatelessWidget {
  const ProfileWorkTab({super.key, this.work = const {}});

  final Map<String, dynamic> work;

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
    String count(String key) => '${AccountProfile.workCount(work[key])}';
    String label(String key, String fallback) => work[key] is Map
        ? (work[key]['label']?.toString() ?? fallback)
        : fallback;

    final items = [
      {
        'title': 'My Leads',
        'subtitle': label('leads', 'Active assignments'),
        'count': count('leads'),
        'color': AppColors.brandLight,
        'icon': CupertinoIcons.person_2,
        'route': '/leads',
      },
      {
        'title': 'Follow-ups',
        'subtitle': label('followups', 'Scheduled follow-ups'),
        'count': count('followups'),
        'color': AppColors.warning,
        'icon': CupertinoIcons.arrow_turn_down_left,
        'route': '/follow-ups',
      },
      {
        'title': 'Visits',
        'subtitle': label('visits', 'Scheduled'),
        'count': count('visits'),
        'color': AppColors.leadVisit,
        'icon': CupertinoIcons.house_fill,
        'route': '/visits',
      },
      {
        'title': 'Tasks',
        'subtitle': label('tasks', 'Open tasks'),
        'count': count('tasks'),
        'color': AppColors.leadContacted,
        'icon': CupertinoIcons.checkmark_rectangle,
        'route': '/tasks',
      },
      {
        'title': 'Issues',
        'subtitle': label('issues', 'Reported issues'),
        'count': count('issues'),
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
