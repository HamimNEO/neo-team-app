import '../../../../core/router/app_navigation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class TeamWorkOverviewCard extends StatelessWidget {
  final int activeLeads;
  final int followUpsDue;
  final int visitsToday;
  final int openTasks;

  const TeamWorkOverviewCard({
    super.key,
    this.activeLeads = 10,
    this.followUpsDue = 5,
    this.visitsToday = 1,
    this.openTasks = 6,
  });

  Widget _buildRowItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String valueText,
    required Color valueColor,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                ],
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              color: nec.separator.withValues(alpha: 0.3),
              indent: 64,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildRowItem(
            context: context,
            icon: CupertinoIcons.person_2,
            iconColor: AppColors.brandLight,
            title: 'Active Leads',
            valueText: '$activeLeads',
            valueColor: AppColors.brandLight,
            onTap: () => context.pushAppRoute('/leads'),
          ),
          _buildRowItem(
            context: context,
            icon: CupertinoIcons.arrow_turn_down_left,
            iconColor: AppColors.warning,
            title: 'Follow-ups Due',
            valueText: '$followUpsDue',
            valueColor: AppColors.warning,
            onTap: () => context.pushAppRoute('/follow-ups'),
          ),
          _buildRowItem(
            context: context,
            icon: CupertinoIcons.house_fill,
            iconColor: AppColors.leadVisit,
            title: 'Visits Today',
            valueText: '$visitsToday',
            valueColor: AppColors.leadVisit,
            onTap: () => context.pushAppRoute('/visits'),
          ),
          _buildRowItem(
            context: context,
            icon: CupertinoIcons.checkmark_rectangle,
            iconColor: AppColors.leadContacted,
            title: 'Open Tasks',
            valueText: '$openTasks',
            valueColor: AppColors.leadContacted,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
