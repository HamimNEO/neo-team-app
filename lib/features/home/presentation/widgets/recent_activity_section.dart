import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/data/work_item_store.dart';
import 'dashboard_rows.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  IconData _iconFor(String entityType, String event) {
    if (event.contains('completed') || event.contains('resolved')) {
      return CupertinoIcons.check_mark;
    }
    if (entityType == 'lead') {
      return CupertinoIcons.person_2;
    }
    if (entityType == 'department' || entityType == 'team') {
      return CupertinoIcons.building_2_fill;
    }
    if (entityType == 'employee') {
      return CupertinoIcons.person_crop_circle;
    }
    return CupertinoIcons.arrow_right;
  }

  Color _colorFor(String entityType, String event) {
    if (event.contains('completed') || event.contains('resolved')) {
      return AppColors.success;
    }
    if (entityType == 'lead') return AppColors.leadContacted;
    if (entityType == 'work_item') return AppColors.brandLight;
    return AppColors.brandLight;
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return AnimatedBuilder(
      animation: WorkItemStore.instance,
      builder: (context, _) {
        final recent = WorkItemStore.instance.overview.recentActivity;
        final List<Map<String, dynamic>> items;

        if (recent.isNotEmpty) {
          items = recent.take(5).map((a) {
            return {
              'title': a.description,
              'time': _formatTimeAgo(a.createdAt),
              'icon': _iconFor(a.entityType, a.event),
              'color': _colorFor(a.entityType, a.event),
            };
          }).toList();
        } else {
          items = [];
        }

        if (items.isEmpty) {
          return DashboardEmpty(
              message: WorkItemStore.instance.overviewError ??
                  'No recent activity.');
        }
        return Material(
          color: nec.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: items.map((item) {
              final color = item['color'] as Color;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
      },
    );
  }
}
