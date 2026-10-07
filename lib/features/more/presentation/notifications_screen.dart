import '../../../core/router/app_navigation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/notification_action_sheet.dart';
import 'widgets/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  final filterOptions = ['All', 'Unread', 'Leads', 'Work', 'System'];

  late List<Map<String, dynamic>> _newNotifications;
  late List<Map<String, dynamic>> _todayNotifications;
  late List<Map<String, dynamic>> _yesterdayNotifications;
  late List<Map<String, dynamic>> _earlierNotifications;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() {
    _newNotifications = [
      {
        'id': 'n1',
        'title': 'Lead assigned to you',
        'subtitle': 'Blue Wave Resort · Assigned by Rahul Mehta',
        'time': '5m ago',
        'category': 'Leads',
        'icon': CupertinoIcons.person_2,
        'color': AppColors.brandLight,
        'isUnread': true,
        'targetRoute': '/leads/lead_1',
      },
      {
        'id': 'n2',
        'title': 'Follow-up due',
        'subtitle': 'Ocean Nest · Today 4:00 PM · Call',
        'time': '20m ago',
        'category': 'Work',
        'icon': CupertinoIcons.arrow_turn_down_left,
        'color': AppColors.warning,
        'isUnread': true,
        'targetRoute': '/follow-ups',
      },
    ];

    _todayNotifications = [
      {
        'id': 'n3',
        'title': 'Follow-up overdue',
        'subtitle': 'Sea Pearl Resort · 2h overdue',
        'time': '2h ago',
        'category': 'Work',
        'icon': CupertinoIcons.exclamationmark_triangle,
        'color': AppColors.error,
        'isUnread': true,
        'targetRoute': '/follow-ups',
      },
      {
        'id': 'n4',
        'title': 'Visit starts in 1 hour',
        'subtitle': 'Green Palm Hotel · 11:00 AM · Cox\'s Bazar',
        'time': '1h ago',
        'category': 'Work',
        'icon': CupertinoIcons.house_fill,
        'color': AppColors.leadVisit,
        'isUnread': true,
        'targetRoute': '/visits',
      },
      {
        'id': 'n5',
        'title': 'Task assigned to you',
        'subtitle': 'Prepare product demo · Blue Wave Resort',
        'time': '2h ago',
        'category': 'Work',
        'icon': CupertinoIcons.checkmark_square,
        'color': AppColors.leadContacted,
        'isUnread': false,
        'targetRoute': '/tasks',
      },
      {
        'id': 'n6',
        'title': 'Issue assigned to you',
        'subtitle': 'Guest App login problem · High · NEC-128',
        'time': '3h ago',
        'category': 'Work',
        'icon': CupertinoIcons.exclamationmark_octagon,
        'color': AppColors.error,
        'isUnread': false,
        'targetRoute': '/issues',
      },
    ];

    _yesterdayNotifications = [
      {
        'id': 'n7',
        'title': 'New lead in your territory',
        'subtitle': 'Hotel Sea Crown · Cox\'s Bazar',
        'time': 'Yesterday',
        'category': 'Leads',
        'icon': CupertinoIcons.person_2,
        'color': AppColors.success,
        'isUnread': false,
        'targetRoute': '/leads',
      },
      {
        'id': 'n8',
        'title': 'Issue resolved',
        'subtitle': 'Payment gateway timeout · NEC-126 · Resolved by Priya',
        'time': 'Yesterday',
        'category': 'Work',
        'icon': CupertinoIcons.checkmark_alt_circle,
        'color': AppColors.success,
        'isUnread': false,
        'targetRoute': '/issues',
      },
    ];

    _earlierNotifications = [
      {
        'id': 'n9',
        'title': 'Your access was updated',
        'subtitle': 'Lead Management permissions have been updated.',
        'time': '2 days ago',
        'category': 'System',
        'icon': CupertinoIcons.shield,
        'color': AppColors.warning,
        'isUnread': false,
        'targetRoute': '/settings',
      },
      {
        'id': 'n10',
        'title': 'NEC TEAM updated',
        'subtitle': 'Version 2.0 · New features available.',
        'time': '3 days ago',
        'category': 'System',
        'icon': CupertinoIcons.bell,
        'color': AppColors.brandLight,
        'isUnread': false,
        'targetRoute': '/appearance',
      },
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _newNotifications) {
        item['isUnread'] = false;
      }
      for (var item in _todayNotifications) {
        item['isUnread'] = false;
      }
      for (var item in _yesterdayNotifications) {
        item['isUnread'] = false;
      }
      for (var item in _earlierNotifications) {
        item['isUnread'] = false;
      }
    });
  }

  int get _totalUnreadCount {
    int count = 0;
    final all = [
      ..._newNotifications,
      ..._todayNotifications,
      ..._yesterdayNotifications,
      ..._earlierNotifications,
    ];
    for (var item in all) {
      if (item['isUnread'] == true) count++;
    }
    return count;
  }

  void _openActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NotificationActionSheet(
        onMarkAllAsRead: _markAllAsRead,
      ),
    );
  }

  bool _matchesFilter(Map<String, dynamic> item) {
    if (_selectedFilter == 'All') return true;
    if (_selectedFilter == 'Unread') return item['isUnread'] == true;
    return item['category'] == _selectedFilter;
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final filtered = items.where(_matchesFilter).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    final unreadInGroup = filtered.where((e) => e['isUnread'] == true).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (unreadInGroup > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadInGroup',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: nec.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(filtered.length, (index) {
                final item = filtered[index];
                final isLast = index == filtered.length - 1;

                return Column(
                  children: [
                    NotificationItem(
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                      time: item['time'] as String,
                      icon: item['icon'] as IconData,
                      iconColor: item['color'] as Color,
                      isUnread: item['isUnread'] as bool,
                      onTap: () {
                        setState(() {
                          item['isUnread'] = false;
                        });
                        context.pushAppRoute(item['targetRoute'] as String);
                      },
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.3),
                        indent: 62,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final unreadCount = _totalUnreadCount;

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
                  unreadCount > 0
                      ? 'Notifications ($unreadCount)'
                      : 'Notifications',
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
                onPressed: _openActionSheet,
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: nec.brand,
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
        child: Column(
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: filterOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = filterOptions[index];
                  final isSelected = _selectedFilter == option;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = option;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? nec.brand.withValues(alpha: 0.15)
                            : nec.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? nec.brand
                              : nec.separator.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? nec.brand : nec.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildSection(
                      context: context,
                      title: 'NEW',
                      items: _newNotifications,
                    ),
                    _buildSection(
                      context: context,
                      title: 'TODAY',
                      items: _todayNotifications,
                    ),
                    _buildSection(
                      context: context,
                      title: 'YESTERDAY',
                      items: _yesterdayNotifications,
                    ),
                    _buildSection(
                      context: context,
                      title: 'EARLIER',
                      items: _earlierNotifications,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
