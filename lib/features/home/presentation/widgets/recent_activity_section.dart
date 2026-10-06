import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final activities = [
      {
        'title': 'Shahina completed follow-up with Blue Wave Resort',
        'time': '15m ago',
        'icon': CupertinoIcons.check_mark,
        'color': AppColors.success,
      },
      {
        'title': 'Karim moved Ocean Paradise Hotel to Negotiation',
        'time': '1h ago',
        'icon': CupertinoIcons.arrow_up_right,
        'color': AppColors.brandLight,
      },
      {
        'title': 'Rahul assigned Sea Pearl Resort to Shahina Akter',
        'time': '2h ago',
        'icon': CupertinoIcons.arrow_right,
        'color': AppColors.leadContacted,
      },
      {
        'title': 'Priya resolved issue: Guest App login problem',
        'time': '3h ago',
        'icon': CupertinoIcons.check_mark,
        'color': AppColors.success,
      },
    ];

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: activities.map((item) {
          final color = item['color'] as Color;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: color,
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['time'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
