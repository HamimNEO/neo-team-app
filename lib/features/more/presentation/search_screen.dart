import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/staff_access_store.dart';
import '../../../core/storage/preferences_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../leads/data/lead_store.dart';
import '../../tasks/data/work_item_store.dart';
import '../../team/data/employee_store.dart';

class SearchResultItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String route;
  final String? badgeText;
  final Color? badgeColor;
  final List<String> searchTokens;

  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.route,
    required this.searchTokens,
    this.badgeText,
    this.badgeColor,
  });
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  static const _recentSearchesKey = 'nec_recent_searches_v1';
  final _prefs = const PreferencesStore();

  List<String> _recentSearches = [];
  String _selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecentSearches();

    LeadStore.instance.addListener(_onStoreUpdated);
    EmployeeStore.instance.addListener(_onStoreUpdated);
    WorkItemStore.instance.addListener(_onStoreUpdated);

    LeadStore.instance.load();
    EmployeeStore.instance.load();
    WorkItemStore.instance.load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    LeadStore.instance.removeListener(_onStoreUpdated);
    EmployeeStore.instance.removeListener(_onStoreUpdated);
    WorkItemStore.instance.removeListener(_onStoreUpdated);
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _onStoreUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentSearches() async {
    try {
      final raw = await _prefs.read(_recentSearchesKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded.map((e) => e.toString()).toList();
          if (list.isNotEmpty && mounted) {
            setState(() {
              _recentSearches = list;
            });
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _recentSearches = _initialRealSuggestions();
      });
    }
  }

  List<String> _initialRealSuggestions() {
    final list = <String>[];
    for (final l in LeadStore.instance.leads.take(2)) {
      if (!list.contains(l.company)) list.add(l.company);
    }
    for (final e in EmployeeStore.instance.employees.take(1)) {
      if (!list.contains(e.name)) list.add(e.name);
    }
    for (final t in WorkItemStore.instance.tasks.take(1)) {
      if (!list.contains(t.title)) list.add(t.title);
    }
    if (list.isEmpty) {
      return ['Sea Pearl Resort', 'Yeapas', 'Client Meeting'];
    }
    return list;
  }

  Future<void> _saveRecentSearches() async {
    try {
      await _prefs.write(_recentSearchesKey, jsonEncode(_recentSearches));
    } catch (_) {}
  }

  void _addRecentSearch(String term) {
    if (term.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(term);
      _recentSearches.insert(0, term);
      if (_recentSearches.length > 8) {
        _recentSearches = _recentSearches.sublist(0, 8);
      }
    });
    _saveRecentSearches();
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearches();
  }

  void _removeRecentSearch(String item) {
    setState(() {
      _recentSearches.remove(item);
    });
    _saveRecentSearches();
  }

  void _selectSearchTerm(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.collapsed(offset: term.length);
  }

  void _navigateTo(String route) {
    FocusScope.of(context).unfocus();
    if (route == '/leads' ||
        route == '/tasks' ||
        route == '/home' ||
        route == '/more') {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  List<SearchResultItem> _getAllItems() {
    final items = <SearchResultItem>[];

    for (final lead in LeadStore.instance.leads) {
      final sub = [
        if (lead.location.isNotEmpty) lead.location,
        if (lead.type.isNotEmpty) lead.type,
        if (lead.contactName != null && lead.contactName!.trim().isNotEmpty)
          'Contact: ${lead.contactName!.trim()}',
      ].join(' · ');

      items.add(
        SearchResultItem(
          id: lead.id,
          title: lead.company,
          subtitle: sub.isNotEmpty ? sub : 'Lead',
          category: 'Leads',
          route: '/leads/${lead.id}',
          badgeText: lead.status,
          badgeColor: AppColors.brandLight,
          searchTokens: [
            lead.company,
            lead.contactName ?? '',
            lead.phone ?? '',
            lead.location,
            lead.type,
            lead.status,
          ],
        ),
      );
    }

    for (final emp in EmployeeStore.instance.employees) {
      final sub = [
        emp.designation.isNotEmpty ? emp.designation : emp.role,
        if (emp.department.isNotEmpty) emp.department,
        if (emp.phone.isNotEmpty) emp.phone,
      ].join(' · ');

      items.add(
        SearchResultItem(
          id: emp.id,
          title: emp.name,
          subtitle: sub.isNotEmpty ? sub : 'Team Member',
          category: 'People',
          route: '/employee/${emp.id}',
          badgeText: emp.role.toUpperCase(),
          badgeColor: AppColors.leadContacted,
          searchTokens: [
            emp.name,
            emp.designation,
            emp.role,
            emp.department,
            emp.phone,
            emp.email,
          ],
        ),
      );
    }

    for (final task in WorkItemStore.instance.tasks) {
      final sub = [
        'Task',
        if (task.priority.isNotEmpty) task.priority.toUpperCase(),
        task.status,
        if (task.leadName != null && task.leadName!.isNotEmpty) task.leadName!,
      ].join(' · ');

      items.add(
        SearchResultItem(
          id: task.id,
          title: task.title,
          subtitle: sub,
          category: 'Tasks',
          route: '/tasks/${task.id}',
          badgeText: task.status,
          badgeColor: AppColors.brandLight,
          searchTokens: [
            task.title,
            task.description,
            task.priority,
            task.status,
            task.leadName ?? '',
          ],
        ),
      );
    }

    for (final visit in WorkItemStore.instance.visits) {
      final visitLocation =
          visit.metadata['location']?.toString() ?? visit.leadLocation ?? '';
      final sub = [
        'Visit',
        if (visit.leadName != null && visit.leadName!.isNotEmpty)
          visit.leadName!
        else if (visitLocation.isNotEmpty)
          visitLocation,
        visit.status,
      ].join(' · ');

      items.add(
        SearchResultItem(
          id: visit.id,
          title: visit.title,
          subtitle: sub,
          category: 'Visits',
          route: '/visit-details/${visit.id}',
          badgeText: visit.status,
          badgeColor: AppColors.warning,
          searchTokens: [
            visit.title,
            visitLocation,
            visit.leadName ?? '',
            visit.status,
          ],
        ),
      );
    }

    final followUps = WorkItemStore.instance.followUps;
    for (final f in followUps) {
      final title = f.title.isNotEmpty
          ? f.title
          : 'Follow-up with ${f.leadName ?? "Client"}';
      final sub = [
        'Follow-up',
        if (f.leadName != null && f.leadName!.isNotEmpty) f.leadName!,
        f.status,
      ].join(' · ');

      items.add(
        SearchResultItem(
          id: f.id,
          title: title,
          subtitle: sub,
          category: 'Follow-ups',
          route: '/follow-up-details/${f.id}',
          badgeText: f.status,
          badgeColor: const Color(0xFF6355F6),
          searchTokens: [
            f.title,
            f.description,
            f.leadName ?? '',
            f.status,
          ],
        ),
      );
    }

    for (final issue in WorkItemStore.instance.issues) {
      final sub = [
        'Issue',
        if (issue.priority.isNotEmpty) issue.priority.toUpperCase(),
        issue.status,
      ].join(' · ');

      items.add(
        SearchResultItem(
          id: issue.id,
          title: issue.title,
          subtitle: sub,
          category: 'Issues',
          route: '/issues/${issue.id}',
          badgeText: issue.status,
          badgeColor: AppColors.error,
          searchTokens: [
            issue.title,
            issue.description,
            issue.priority,
            issue.status,
          ],
        ),
      );
    }

    return items;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Leads':
        return CupertinoIcons.person_2_fill;
      case 'People':
        return CupertinoIcons.person_fill;
      case 'Tasks':
        return CupertinoIcons.checkmark_square_fill;
      case 'Visits':
        return CupertinoIcons.placemark_fill;
      case 'Follow-ups':
        return CupertinoIcons.phone_fill;
      case 'Issues':
      default:
        return CupertinoIcons.exclamationmark_circle_fill;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Leads':
        return AppColors.brandLight;
      case 'People':
        return AppColors.leadContacted;
      case 'Tasks':
        return AppColors.brandLight;
      case 'Visits':
        return AppColors.warning;
      case 'Follow-ups':
        return const Color(0xFF6355F6);
      case 'Issues':
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _searchController.text.trim().toLowerCase();

    final allItems = _getAllItems();

    final matchingResults = query.isEmpty
        ? <SearchResultItem>[]
        : allItems.where((item) {
            final accessGranted = StaffAccessStore.instance.canOpen(item.route);
            if (!accessGranted) return false;

            if (_selectedCategoryFilter != 'All' &&
                item.category != _selectedCategoryFilter) {
              return false;
            }

            final titleMatch = item.title.toLowerCase().contains(query);
            final subtitleMatch = item.subtitle.toLowerCase().contains(query);
            final catMatch = item.category.toLowerCase().contains(query);
            final tokenMatch =
                item.searchTokens.any((t) => t.toLowerCase().contains(query));

            return titleMatch || subtitleMatch || catMatch || tokenMatch;
          }).toList();

    final categoriesWithCounts = <String, int>{'All': 0};
    if (query.isNotEmpty) {
      for (final item in allItems) {
        if (!StaffAccessStore.instance.canOpen(item.route)) continue;
        final titleMatch = item.title.toLowerCase().contains(query);
        final subtitleMatch = item.subtitle.toLowerCase().contains(query);
        final catMatch = item.category.toLowerCase().contains(query);
        final tokenMatch =
            item.searchTokens.any((t) => t.toLowerCase().contains(query));

        if (titleMatch || subtitleMatch || catMatch || tokenMatch) {
          categoriesWithCounts['All'] = (categoriesWithCounts['All'] ?? 0) + 1;
          categoriesWithCounts[item.category] =
              (categoriesWithCounts[item.category] ?? 0) + 1;
        }
      }
    }

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
                  'Search',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 60),
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
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? nec.surface
                      : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 18,
                      color: nec.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: false,
                        style: TextStyle(
                          fontSize: 15,
                          color: nec.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search leads, people, tasks...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: nec.textTertiary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (term) {
                          if (term.trim().isNotEmpty) {
                            _addRecentSearch(term.trim());
                          }
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _selectedCategoryFilter = 'All';
                          });
                        },
                        child: Icon(
                          CupertinoIcons.clear_thick_circled,
                          size: 18,
                          color: nec.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (query.isNotEmpty) ...[
                if (categoriesWithCounts.length > 2) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categoriesWithCounts.entries.map((entry) {
                        final cat = entry.key;
                        final count = entry.value;
                        final isSelected = _selectedCategoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryFilter = cat;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.brandLight
                                    : (isDark
                                        ? nec.surface
                                        : nec.separator
                                            .withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.brandLight
                                      : nec.separator.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                '$cat ($count)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : nec.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'RESULTS (${matchingResults.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                if (matchingResults.isEmpty)
                  _buildNoResultsState(nec, query)
                else
                  Material(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: List.generate(matchingResults.length, (index) {
                        final item = matchingResults[index];
                        final isLast = index == matchingResults.length - 1;
                        final cat = item.category;

                        return Column(
                          children: [
                            ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(cat)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getCategoryIcon(cat),
                                  color: _getCategoryColor(cat),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                item.subtitle,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: nec.textTertiary,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.badgeText != null &&
                                      item.badgeText!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (item.badgeColor ?? nec.brand)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.badgeText!,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: item.badgeColor ?? nec.brand,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 15,
                                    color: nec.textTertiary,
                                  ),
                                ],
                              ),
                              onTap: () {
                                _addRecentSearch(item.title);
                                _navigateTo(item.route);
                              },
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                color: nec.separator.withValues(alpha: 0.2),
                                indent: 16,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
              ] else ...[
                if (_recentSearches.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: nec.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearRecentSearches,
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: nec.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: List.generate(_recentSearches.length, (index) {
                        final item = _recentSearches[index];
                        final isLast = index == _recentSearches.length - 1;

                        return Column(
                          children: [
                            ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 2),
                              leading: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? nec.bg
                                      : nec.separator.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.clock_fill,
                                  size: 14,
                                  color: nec.textSecondary,
                                ),
                              ),
                              title: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: nec.textPrimary,
                                ),
                              ),
                              trailing: GestureDetector(
                                onTap: () => _removeRecentSearch(item),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  size: 16,
                                  color: nec.textTertiary,
                                ),
                              ),
                              onTap: () => _selectSearchTerm(item),
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
                  const SizedBox(height: 24),
                ],
                Text(
                  'BROWSE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    if (StaffAccessStore.instance.canOpen('/leads'))
                      _buildBrowseCard(
                        nec,
                        title: 'Leads',
                        icon: CupertinoIcons.person_2_fill,
                        iconColor: AppColors.brandLight,
                        onTap: () => _navigateTo('/leads'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/tasks'))
                      _buildBrowseCard(
                        nec,
                        title: 'Tasks',
                        icon: CupertinoIcons.checkmark_square_fill,
                        iconColor: AppColors.brandLight,
                        onTap: () => _navigateTo('/tasks'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/visits'))
                      _buildBrowseCard(
                        nec,
                        title: 'Visits',
                        icon: CupertinoIcons.placemark_fill,
                        iconColor: AppColors.warning,
                        onTap: () => _navigateTo('/visits'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/follow-ups'))
                      _buildBrowseCard(
                        nec,
                        title: 'Follow-ups',
                        icon: CupertinoIcons.phone_fill,
                        iconColor: const Color(0xFF6355F6),
                        onTap: () => _navigateTo('/follow-ups'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/issues'))
                      _buildBrowseCard(
                        nec,
                        title: 'Issues',
                        icon: CupertinoIcons.exclamationmark_circle_fill,
                        iconColor: AppColors.error,
                        onTap: () => _navigateTo('/issues'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/team'))
                      _buildBrowseCard(
                        nec,
                        title: 'People',
                        icon: CupertinoIcons.person_fill,
                        iconColor: AppColors.leadContacted,
                        onTap: () => _navigateTo('/team'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseCard(
    NecColors nec, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(NecColors nec, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: nec.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.search,
                size: 28,
                color: nec.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No leads, people, tasks or issues match "$query".',
              style: TextStyle(
                fontSize: 13,
                color: nec.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
