import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/activity_filter_sheet.dart';
import 'widgets/activity_list_item.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'All Activity';

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ActivityFilterSheet(
        selectedFilter: _selectedFilter,
        onFilterSelected: (filter) {
          setState(() {
            _selectedFilter = filter;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final todayActivities = [
      {
        'user': 'You',
        'action': 'completed follow-up with',
        'entity': 'Blue Wave Resort',
        'time': '2:15 PM',
        'icon': CupertinoIcons.arrow_turn_down_left,
        'color': AppColors.warning,
        'category': 'Follow-ups',
        'isMine': true,
      },
      {
        'user': 'Das',
        'action': 'resolved issue',
        'entity': 'Guest App login problem',
        'time': '1:20 PM',
        'icon': CupertinoIcons.exclamationmark_octagon,
        'color': AppColors.error,
        'category': 'Issues',
        'isMine': false,
      },
      {
        'user': 'You',
        'action': 'moved lead to Negotiation',
        'entity': 'Ocean Paradise Hotel',
        'time': '11:40 AM',
        'icon': CupertinoIcons.person_2,
        'color': AppColors.brandLight,
        'category': 'Leads',
        'isMine': true,
      },
      {
        'user': 'You',
        'action': 'completed visit at',
        'entity': 'Sea Pearl Resort',
        'time': '10:05 AM',
        'icon': CupertinoIcons.house_fill,
        'color': AppColors.leadVisit,
        'category': 'Visits',
        'isMine': true,
      },
      {
        'user': 'Hossain',
        'action': 'completed task',
        'entity': 'Prepare weekly report',
        'time': '9:30 AM',
        'icon': CupertinoIcons.checkmark_rectangle,
        'color': AppColors.leadContacted,
        'category': 'Tasks',
        'isMine': false,
      },
    ];

    final yesterdayActivities = [
      {
        'user': 'Mehta',
        'action': 'assigned lead to Shahina',
        'entity': 'Blue Wave Resort',
        'time': '5:40 PM',
        'icon': CupertinoIcons.person_2,
        'color': AppColors.brandLight,
        'category': 'Leads',
        'isMine': false,
      },
      {
        'user': 'Hossain',
        'action': 'scheduled follow-up with',
        'entity': 'Green Palm Hotel',
        'time': '3:15 PM',
        'icon': CupertinoIcons.arrow_turn_down_left,
        'color': AppColors.warning,
        'category': 'Follow-ups',
        'isMine': false,
      },
    ];

    bool matchesFilter(Map<String, dynamic> item) {
      if (_selectedFilter == 'All Activity') return true;
      if (_selectedFilter == 'My Activity') return item['isMine'] == true;
      return item['category'] == _selectedFilter;
    }

    final filteredToday = todayActivities.where(matchesFilter).toList();
    final filteredYesterday = yesterdayActivities.where(matchesFilter).toList();

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: nec.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: nec.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  'Activity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openFilterSheet,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.line_horizontal_3_decrease,
                      size: 16,
                      color: nec.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: nec.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: nec.separator.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (filteredToday.isNotEmpty) ...[
                Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: List.generate(filteredToday.length, (index) {
                      final item = filteredToday[index];
                      final isLast = index == filteredToday.length - 1;

                      return Column(
                        children: [
                          ActivityListItem(
                            user: item['user'] as String,
                            action: item['action'] as String,
                            entity: item['entity'] as String,
                            time: item['time'] as String,
                            icon: item['icon'] as IconData,
                            iconColor: item['color'] as Color,
                            onTap: () => context.push('/leads/lead_1'),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: nec.separator.withValues(alpha: 0.3),
                              indent: 66,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (filteredYesterday.isNotEmpty) ...[
                Text(
                  'YESTERDAY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: List.generate(filteredYesterday.length, (index) {
                      final item = filteredYesterday[index];
                      final isLast = index == filteredYesterday.length - 1;

                      return Column(
                        children: [
                          ActivityListItem(
                            user: item['user'] as String,
                            action: item['action'] as String,
                            entity: item['entity'] as String,
                            time: item['time'] as String,
                            icon: item['icon'] as IconData,
                            iconColor: item['color'] as Color,
                            onTap: () => context.push('/leads/lead_1'),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: nec.separator.withValues(alpha: 0.3),
                              indent: 66,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (filteredToday.isEmpty && filteredYesterday.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No activities for $_selectedFilter',
                      style: TextStyle(
                        fontSize: 14,
                        color: nec.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
