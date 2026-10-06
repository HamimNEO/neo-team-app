import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/mock_follow_ups.dart';
import '../domain/models/follow_up.dart';
import 'widgets/add_follow_up_sheet.dart';
import 'widgets/follow_up_card_item.dart';

class FollowUpsScreen extends StatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  State<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends State<FollowUpsScreen> {
  String _selectedTab = 'Today';

  bool _isSearching = false;
  final _searchController = TextEditingController();

  late List<FollowUp> _followUps;

  @override
  void initState() {
    super.initState();
    _followUps = List.from(mockFollowUps);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddFollowUpSheet() async {
    if (!StaffAccessStore.instance.allows(StaffPermission.scheduleFollowUp)) {
      return;
    }
    final result = await showModalBottomSheet<FollowUp>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddFollowUpSheet(),
    );
    if (result != null) {
      setState(() {
        _followUps.insert(0, result);
      });
    }
  }

  void _toggleComplete(FollowUp item) {
    setState(() {
      item.isCompleted = true;
      item.statusGroup = 'Completed Today';
      item.resultTag = 'Interested';
    });
    NecToast.show(
      context,
      message: 'Follow-up marked as completed',
      type: NecToastType.success,
    );
  }

  List<FollowUp> _getFilteredFollowUps() {
    return _followUps.where((item) {
      if (_selectedTab == 'Today') {
        if (item.isCompleted) return false;
        if (item.statusGroup != 'Overdue' && item.statusGroup != 'Today') {
          return false;
        }
      } else if (_selectedTab == 'Upcoming') {
        if (item.isCompleted) return false;
        if (item.statusGroup != 'Tomorrow' && item.statusGroup != 'This Week') {
          return false;
        }
      } else if (_selectedTab == 'Completed') {
        if (!item.isCompleted) return false;
      }

      if (_isSearching && _searchController.text.trim().isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        final matchLead = item.leadName.toLowerCase().contains(query);
        final matchPurpose = item.purpose.toLowerCase().contains(query);
        final matchAssignee = item.assigneeName.toLowerCase().contains(query);
        if (!matchLead && !matchPurpose && !matchAssignee) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final todayCount = _followUps
        .where((f) => !f.isCompleted && f.statusGroup == 'Today')
        .length;
    final overdueCount = _followUps
        .where((f) => !f.isCompleted && f.statusGroup == 'Overdue')
        .length;
    final upcomingCount = _followUps
        .where((f) =>
            !f.isCompleted &&
            (f.statusGroup == 'Tomorrow' || f.statusGroup == 'This Week'))
        .length;
    final doneCount = _followUps.where((f) => f.isCompleted).length;

    final filteredList = _getFilteredFollowUps();

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _isSearching
              ? Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.search,
                              size: 16,
                              color: nec.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: nec.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search follow-ups...',
                                  hintStyle: TextStyle(
                                    fontSize: 15,
                                    color: nec.textTertiary,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                },
                                child: Icon(
                                  CupertinoIcons.clear_thick_circled,
                                  size: 16,
                                  color: nec.textTertiary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                        });
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.brandLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.pop();
                        }
                      },
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
                        'Follow-ups',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: nec.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: nec.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.search,
                          size: 18,
                          color: nec.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: StaffAccessStore.instance
                              .allows(StaffPermission.scheduleFollowUp)
                          ? _openAddFollowUpSheet
                          : null,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.brandLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildStatCard(
                    nec, isDark, '$todayCount', 'Today', AppColors.brandLight,
                    () {
                  setState(() => _selectedTab = 'Today');
                }),
                const SizedBox(width: 8),
                _buildStatCard(
                    nec, isDark, '$overdueCount', 'Overdue', AppColors.error,
                    () {
                  setState(() => _selectedTab = 'Today');
                }),
                const SizedBox(width: 8),
                _buildStatCard(
                    nec, isDark, '$upcomingCount', 'Upcoming', nec.textPrimary,
                    () {
                  setState(() => _selectedTab = 'Upcoming');
                }),
                const SizedBox(width: 8),
                _buildStatCard(
                    nec, isDark, '$doneCount', 'Done', AppColors.success, () {
                  setState(() => _selectedTab = 'Completed');
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSubTabBar(nec, overdueCount),
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(nec)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: _buildGroupedSections(nec, filteredList),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    NecColors nec,
    bool isDark,
    String value,
    String label,
    Color valueColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: nec.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: nec.separator.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: nec.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabBar(NecColors nec, int overdueCount) {
    final tabs = ['Today', 'Upcoming', 'Completed'];
    final activeIndex = tabs.indexOf(_selectedTab);

    return Column(
      children: [
        Row(
          children: tabs.map((tab) {
            final isSelected = _selectedTab == tab;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedTab = tab;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tab,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.brandLight
                              : nec.textTertiary,
                        ),
                      ),
                      if (tab == 'Today' && overdueCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$overdueCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 3;
            return Stack(
              children: [
                Container(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.3),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: tabWidth * activeIndex,
                  width: tabWidth,
                  height: 2.5,
                  child: Container(
                    color: AppColors.brandLight,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildGroupedSections(NecColors nec, List<FollowUp> items) {
    final List<Widget> widgets = [];

    final Map<String, List<FollowUp>> groups = {};
    for (var item in items) {
      groups.putIfAbsent(item.statusGroup, () => []).add(item);
    }

    final groupOrder = [
      'Overdue',
      'Today',
      'Tomorrow',
      'This Week',
      'Completed Today',
      'Yesterday',
    ];

    for (var gName in groupOrder) {
      if (!groups.containsKey(gName) || groups[gName]!.isEmpty) continue;

      final gItems = groups[gName]!;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Row(
            children: [
              if (gName == 'Overdue') ...[
                const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                const Text(
                  'OVERDUE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                    letterSpacing: 0.5,
                  ),
                ),
              ] else
                Text(
                  gName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ),
      );

      widgets.add(
        Material(
          color: nec.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(gItems.length, (idx) {
              final item = gItems[idx];
              final isLast = idx == gItems.length - 1;

              return Column(
                children: [
                  FollowUpCardItem(
                    item: item,
                    onTap: () {
                      context.push('/follow-up-details/${item.id}');
                    },
                    onToggleComplete: (val) {
                      _toggleComplete(item);
                    },
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                    ),
                ],
              );
            }),
          ),
        ),
      );

      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildEmptyState(NecColors nec) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandLight.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 36,
                color: AppColors.brandLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Follow-ups Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching && _searchController.text.trim().isNotEmpty
                  ? 'No follow-ups match "${_searchController.text.trim()}". Try clearing your search query.'
                  : 'You are all caught up! No follow-ups scheduled in this section right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: nec.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
