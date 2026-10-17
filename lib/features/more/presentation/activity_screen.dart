import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/activity_filter_sheet.dart';
import 'widgets/activity_list_item.dart';
import 'widgets/activity_skeleton.dart';

import '../data/activity_store.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'All Activity';

  @override
  void initState() {
    super.initState();
    ActivityStore.instance.load();
  }

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
          final apiFilter = switch (filter) {
            'My Activity' => 'mine',
            'Follow-ups' => 'followups',
            'Visits' => 'visits',
            'Tasks' => 'tasks',
            'Issues' => 'issues',
            'Leads' => 'leads',
            _ => 'all',
          };
          ActivityStore.instance.load(filter: apiFilter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return AnimatedBuilder(
      animation: ActivityStore.instance,
      builder: (context, _) {
        final store = ActivityStore.instance;

        bool matchesFilter(Map<String, dynamic> item) {
          if (_selectedFilter == 'All Activity') return true;
          if (_selectedFilter == 'My Activity') return item['isMine'] == true;
          return item['category'] == _selectedFilter;
        }

        final todayList = store.todayActivities.where(matchesFilter).toList();
        final yesterdayList =
            store.yesterdayActivities.where(matchesFilter).toList();
        final earlierList =
            store.earlierActivities.where(matchesFilter).toList();

        final showSkeleton = store.isLoading && store.totalActivitiesCount == 0;

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
            child: showSkeleton
                ? const ActivitySkeleton()
                : RefreshIndicator(
                    onRefresh: () => ActivityStore.instance.load(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (todayList.isNotEmpty) ...[
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
                                children:
                                    List.generate(todayList.length, (index) {
                                  final item = todayList[index];
                                  final isLast = index == todayList.length - 1;

                                  return Column(
                                    children: [
                                      ActivityListItem(
                                        user: item['user'] as String? ?? '',
                                        action: item['action'] as String? ?? '',
                                        entity: item['entity'] as String? ?? '',
                                        time: item['time'] as String? ?? '',
                                        icon: (item['icon'] as IconData?) ??
                                            CupertinoIcons.bolt_fill,
                                        iconColor: (item['color'] as Color?) ??
                                            nec.brand,
                                        onTap: () =>
                                            context.push('/leads/lead_1'),
                                      ),
                                      if (!isLast)
                                        Divider(
                                          height: 1,
                                          color: nec.separator
                                              .withValues(alpha: 0.3),
                                          indent: 66,
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (yesterdayList.isNotEmpty) ...[
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
                                children: List.generate(yesterdayList.length,
                                    (index) {
                                  final item = yesterdayList[index];
                                  final isLast =
                                      index == yesterdayList.length - 1;

                                  return Column(
                                    children: [
                                      ActivityListItem(
                                        user: item['user'] as String? ?? '',
                                        action: item['action'] as String? ?? '',
                                        entity: item['entity'] as String? ?? '',
                                        time: item['time'] as String? ?? '',
                                        icon: (item['icon'] as IconData?) ??
                                            CupertinoIcons.bolt_fill,
                                        iconColor: (item['color'] as Color?) ??
                                            nec.brand,
                                        onTap: () =>
                                            context.push('/leads/lead_1'),
                                      ),
                                      if (!isLast)
                                        Divider(
                                          height: 1,
                                          color: nec.separator
                                              .withValues(alpha: 0.3),
                                          indent: 66,
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (earlierList.isNotEmpty) ...[
                            Text(
                              'EARLIER',
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
                                children:
                                    List.generate(earlierList.length, (index) {
                                  final item = earlierList[index];
                                  final isLast =
                                      index == earlierList.length - 1;

                                  return Column(
                                    children: [
                                      ActivityListItem(
                                        user: item['user'] as String? ?? '',
                                        action: item['action'] as String? ?? '',
                                        entity: item['entity'] as String? ?? '',
                                        time: item['time'] as String? ?? '',
                                        icon: (item['icon'] as IconData?) ??
                                            CupertinoIcons.bolt_fill,
                                        iconColor: (item['color'] as Color?) ??
                                            nec.brand,
                                        onTap: () =>
                                            context.push('/leads/lead_1'),
                                      ),
                                      if (!isLast)
                                        Divider(
                                          height: 1,
                                          color: nec.separator
                                              .withValues(alpha: 0.3),
                                          indent: 66,
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (todayList.isEmpty &&
                              yesterdayList.isEmpty &&
                              earlierList.isEmpty)
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
          ),
        );
      },
    );
  }
}
