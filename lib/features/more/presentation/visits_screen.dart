import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mock_visits.dart';
import '../domain/models/visit.dart';
import 'widgets/schedule_visit_sheet.dart';
import 'widgets/visit_card_item.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  String _selectedTab = 'Today';

  bool _isSearching = false;
  final _searchController = TextEditingController();

  late List<Visit> _visits;

  @override
  void initState() {
    super.initState();
    _visits = List.from(mockVisits);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openScheduleVisitSheet() async {
    if (!StaffAccessStore.instance.allows(StaffPermission.scheduleVisit)) {
      return;
    }
    final result = await showModalBottomSheet<Visit>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ScheduleVisitSheet(),
    );
    if (result != null) {
      setState(() {
        _visits.insert(0, result);
      });
    }
  }

  List<Visit> _getFilteredVisits() {
    return _visits.where((item) {
      if (_selectedTab == 'Today') {
        if (item.statusGroup != 'Today') return false;
      } else if (_selectedTab == 'Upcoming') {
        if (item.statusGroup != 'Tomorrow' && item.statusGroup != 'This Week') {
          return false;
        }
      } else if (_selectedTab == 'Completed') {
        if (item.statusGroup != 'Needs Report' &&
            item.statusGroup != 'Yesterday' &&
            item.statusGroup != 'Cancelled') {
          return false;
        }
      }

      if (_isSearching && _searchController.text.trim().isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        final matchLead = item.leadName.toLowerCase().contains(query);
        final matchLocation = item.location.toLowerCase().contains(query);
        final matchPurpose = item.purpose.toLowerCase().contains(query);
        final matchAssignee = item.assigneeName.toLowerCase().contains(query);
        if (!matchLead && !matchLocation && !matchPurpose && !matchAssignee) {
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

    final todayCount = _visits.where((v) => v.statusGroup == 'Today').length;
    final upcomingCount = _visits
        .where(
            (v) => v.statusGroup == 'Tomorrow' || v.statusGroup == 'This Week')
        .length;
    final completedCount = _visits.where((v) => v.status == 'Completed').length;
    final reportDueCount =
        _visits.where((v) => v.statusGroup == 'Needs Report').length;

    final filteredList = _getFilteredVisits();

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
                                  hintText: 'Search visits...',
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
                          color: AppColors.warning,
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
                        'Visits',
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
                              .allows(StaffPermission.scheduleVisit)
                          ? _openScheduleVisitSheet
                          : null,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
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
                    nec, isDark, '$todayCount', 'Today', AppColors.warning, () {
                  setState(() => _selectedTab = 'Today');
                }),
                const SizedBox(width: 8),
                _buildStatCard(nec, isDark, '$upcomingCount', 'Upcoming',
                    AppColors.brandLight, () {
                  setState(() => _selectedTab = 'Upcoming');
                }),
                const SizedBox(width: 8),
                _buildStatCard(nec, isDark, '$completedCount', 'Completed',
                    AppColors.success, () {
                  setState(() => _selectedTab = 'Completed');
                }),
                const SizedBox(width: 8),
                _buildStatCard(nec, isDark, '$reportDueCount', 'Report Due',
                    const Color(0xFFFFB340), () {
                  setState(() => _selectedTab = 'Completed');
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSubTabBar(nec, reportDueCount),
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

  Widget _buildSubTabBar(NecColors nec, int reportDueCount) {
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
                          color:
                              isSelected ? AppColors.warning : nec.textTertiary,
                        ),
                      ),
                      if (tab == 'Completed' && reportDueCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB340),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$reportDueCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
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
                    color: AppColors.warning,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildGroupedSections(NecColors nec, List<Visit> items) {
    final List<Widget> widgets = [];

    final Map<String, List<Visit>> groups = {};
    for (var item in items) {
      groups.putIfAbsent(item.statusGroup, () => []).add(item);
    }

    final groupOrder = [
      'Today',
      'Tomorrow',
      'This Week',
      'Needs Report',
      'Yesterday',
      'Cancelled',
    ];

    for (var gName in groupOrder) {
      if (!groups.containsKey(gName) || groups[gName]!.isEmpty) continue;

      final gItems = groups[gName]!;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Row(
            children: [
              if (gName == 'Needs Report') ...[
                const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                const Text(
                  'NEEDS REPORT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
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
                  VisitCardItem(
                    visit: item,
                    onTap: () {
                      context.push('/visit-details/${item.id}');
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
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.house_fill,
                size: 36,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Visits Scheduled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching && _searchController.text.trim().isNotEmpty
                  ? 'No visits match "${_searchController.text.trim()}". Try clearing your search query.'
                  : 'You have no visits scheduled in this section right now.',
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
