import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mock_issues.dart';
import '../domain/models/issue.dart';
import 'widgets/issue_card_item.dart';
import 'widgets/issue_filter_sheet.dart';
import 'widgets/report_issue_sheet.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  String _selectedScope = 'Mine';
  String _selectedTab = 'Open';

  bool _isSearching = false;
  final _searchController = TextEditingController();
  String? _filterPriority;

  late List<Issue> _issues;

  @override
  void initState() {
    super.initState();
    _issues = List.from(mockIssues);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => IssueFilterSheet(
        selectedPriority: _filterPriority,
        onApply: (priority) {
          setState(() {
            _filterPriority = priority;
          });
        },
      ),
    );
  }

  void _openReportIssueSheet() async {
    if (!StaffAccessStore.instance.allows(StaffPermission.reportIssue)) {
      return;
    }
    final result = await showModalBottomSheet<Issue>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const ReportIssueSheet(),
    );
    if (result != null) {
      setState(() {
        _issues.insert(0, result);
      });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'normal':
        return AppColors.brandLight;
      case 'low':
      default:
        return const Color(0xFF8E8E93);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return const Color(0xFF8E8E93);
      case 'assigned':
        return AppColors.brandLight;
      case 'active':
      case 'in progress':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      default:
        return const Color(0xFF8E8E93);
    }
  }

  List<Issue> _getFilteredIssues() {
    return _issues.where((issue) {
      if (_selectedScope == 'Mine') {
        if (!issue.scopeMine && issue.assigneeName != 'Md.') return false;
      } else if (_selectedScope == 'Team') {
        if (!issue.scopeTeam) return false;
      }

      if (_selectedTab == 'Open') {
        if (issue.status == 'Resolved' || issue.status == 'Active') {
          return false;
        }
      } else if (_selectedTab == 'Active') {
        if (issue.status != 'Active' && issue.status != 'In Progress') {
          return false;
        }
      } else if (_selectedTab == 'Resolved') {
        if (issue.status != 'Resolved') return false;
      }

      if (_filterPriority != null && _filterPriority!.isNotEmpty) {
        if (issue.priority.toLowerCase() != _filterPriority!.toLowerCase()) {
          return false;
        }
      }

      if (_isSearching && _searchController.text.trim().isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        final matchTitle = issue.title.toLowerCase().contains(query);
        final matchId = issue.id.toLowerCase().contains(query);
        final matchCategory = issue.category.toLowerCase().contains(query);
        final matchProject = issue.project.toLowerCase().contains(query);
        final matchAssignee =
            issue.assigneeName?.toLowerCase().contains(query) ?? false;
        if (!matchTitle &&
            !matchId &&
            !matchCategory &&
            !matchProject &&
            !matchAssignee) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int _getAttentionCount(List<Issue> scopeIssues) {
    return scopeIssues
        .where((issue) =>
            issue.status != 'Resolved' &&
            (issue.hasRedDot ||
                issue.priority.toLowerCase() == 'urgent' ||
                issue.assigneeName == null))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final filteredIssues = _getFilteredIssues();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scopeIssues = _issues.where((issue) {
      if (_selectedScope == 'Mine') {
        return issue.scopeMine || issue.assigneeName == 'Md.';
      } else if (_selectedScope == 'Team') {
        return issue.scopeTeam;
      }
      return true;
    }).toList();

    final attentionCount =
        _selectedTab == 'Open' ? _getAttentionCount(scopeIssues) : 0;

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
                                  hintText: 'Search issues...',
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
                          color: AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    if (Navigator.canPop(context))
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        color: nec.textPrimary,
                        onPressed: () => context.pop(),
                      ),
                    if (Navigator.canPop(context)) const SizedBox(width: 8),
                    Text(
                      'Issues',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: nec.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
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
                          color:
                              _isSearching ? AppColors.error : nec.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _openFilterSheet,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _filterPriority != null
                              ? AppColors.error.withValues(alpha: 0.2)
                              : nec.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 18,
                          color: _filterPriority != null
                              ? AppColors.error
                              : nec.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: ['Mine', 'Team', 'All'].map((scope) {
                final isSelected = _selectedScope == scope;
                final unselectedBg = isDark
                    ? nec.surface
                    : nec.separator.withValues(alpha: 0.12);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedScope = scope;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.error : unselectedBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          scope,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : nec.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _buildSubTabBar(nec),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (attentionCount > 0)
                  _buildAttentionBanner(nec, attentionCount),
                if (filteredIssues.isEmpty)
                  _buildEmptyState(nec)
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Material(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: List.generate(filteredIssues.length, (index) {
                          final issue = filteredIssues[index];
                          final isLast = index == filteredIssues.length - 1;

                          return Column(
                            children: [
                              IssueCardItem(
                                issueKey: issue.id,
                                title: issue.title,
                                subtitle:
                                    '${issue.category} · ${issue.project}',
                                priority: issue.priority,
                                priorityColor:
                                    _getPriorityColor(issue.priority),
                                status: issue.status,
                                statusColor: _getStatusColor(issue.status),
                                assigneeInitials: issue.assigneeInitials ?? '',
                                assigneeName: issue.assigneeName,
                                date: issue.date,
                                hasRedDot: issue.hasRedDot,
                                onTap: () {
                                  // Can show issue details or options
                                },
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  color: nec.separator.withValues(alpha: 0.3),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          !StaffAccessStore.instance.allows(StaffPermission.reportIssue)
              ? null
              : FloatingActionButton(
                  onPressed: _openReportIssueSheet,
                  backgroundColor: AppColors.error,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
    );
  }

  Widget _buildSubTabBar(NecColors nec) {
    final tabs = ['Open', 'Active', 'Resolved'];
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
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.error : nec.textTertiary,
                    ),
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
                    color: AppColors.error,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttentionBanner(NecColors nec, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: AppColors.error,
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              '$count ${count == 1 ? 'issue needs' : 'issues need'} attention',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
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
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.checkmark_shield_fill,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Issues Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching && _searchController.text.trim().isNotEmpty
                  ? 'No issues match "${_searchController.text.trim()}". Try checking for spelling errors or clear your search query.'
                  : _filterPriority != null
                      ? 'No issues found with priority level "$_filterPriority". Try clearing your filters to see all issues.'
                      : 'Everything looks clear! There are no issues reported in this section right now.',
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
