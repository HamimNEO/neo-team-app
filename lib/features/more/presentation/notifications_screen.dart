import '../../../core/router/app_navigation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/nec_toast.dart';
import 'widgets/notification_skeleton.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/notification_action_sheet.dart';
import 'widgets/notification_item.dart';

import '../data/notification_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  final filterOptions = ['All', 'Unread', 'Leads', 'Work', 'System'];

  @override
  void initState() {
    super.initState();
    NotificationStore.instance.load(filter: 'all');
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationStore.instance.markAllAsRead();
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: 'Unable to mark notifications read. Please retry.',
            type: NecToastType.error);
      }
    }
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
                      onTap: () async {
                        final id = item['id']?.toString();
                        if (id != null && item['isUnread'] == true) {
                          NotificationStore.instance.markAsRead(id).ignore();
                        }
                        if (context.mounted) {
                          final route =
                              NotificationStore.instance.resolveRoute(item);
                          if (route.isNotEmpty && route != '/notifications') {
                            context.pushAppRoute(route);
                          }
                        }
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
    return AnimatedBuilder(
      animation: NotificationStore.instance,
      builder: (context, _) {
        final nec = Theme.of(context).extension<NecColors>()!;
        final store = NotificationStore.instance;
        final newItems = store.newNotifications;
        final todayItems = store.todayNotifications;
        final yesterdayItems = store.yesterdayNotifications;
        final earlierItems = store.earlierNotifications;
        final unreadCount = store.unreadCount;
        final visible = [
          ...newItems,
          ...todayItems,
          ...yesterdayItems,
          ...earlierItems
        ].where(_matchesFilter).length;

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
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
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
                  child: RefreshIndicator(
                    onRefresh: () => NotificationStore.instance
                        .load(filter: 'all', force: true),
                    child: store.isLoading
                        ? const NotificationSkeleton()
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                if (store.error != null)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Column(children: [
                                        Text(store.error!,
                                            style: TextStyle(
                                                color: nec.textSecondary)),
                                        TextButton(
                                            onPressed: () => store.load(
                                                filter: 'all', force: true),
                                            child: const Text('Retry')),
                                      ])),
                                if (visible == 0 && store.error == null)
                                  Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Text('No notifications',
                                          style: TextStyle(
                                              color: nec.textSecondary))),
                                _buildSection(
                                  context: context,
                                  title: 'NEW',
                                  items: newItems,
                                ),
                                _buildSection(
                                  context: context,
                                  title: 'TODAY',
                                  items: todayItems,
                                ),
                                _buildSection(
                                  context: context,
                                  title: 'YESTERDAY',
                                  items: yesterdayItems,
                                ),
                                _buildSection(
                                  context: context,
                                  title: 'EARLIER',
                                  items: earlierItems,
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
