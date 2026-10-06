import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/staff_access_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  final List<String> _recentSearches = [
    'Blue Wave Resort',
    'Shahina Akter',
    'NEC-128',
    'Site visit',
  ];

  final List<Map<String, String>> _allSearchableItems = [
    {
      'title': 'Blue Wave Resort',
      'subtitle': 'Lead · Cox\'s Bazar · Resort',
      'category': 'Leads',
      'route': '/leads/lead_1',
    },
    {
      'title': 'Sea Pearl Resort',
      'subtitle': 'Lead · Cox\'s Bazar · Resort',
      'category': 'Leads',
      'route': '/leads/lead_2',
    },
    {
      'title': 'Green Palm Hotel',
      'subtitle': 'Lead · Sylhet · Hotel',
      'category': 'Leads',
      'route': '/leads/lead_3',
    },
    {
      'title': 'Ocean Nest Hotel',
      'subtitle': 'Lead · Dhaka · Hotel',
      'category': 'Leads',
      'route': '/leads/lead_4',
    },
    {
      'title': 'Shahina Akter',
      'subtitle': 'People · Digital Marketing Executive',
      'category': 'People',
      'route': '/employee/emp_shahina',
    },
    {
      'title': 'Mahmud Hasan',
      'subtitle': 'People · General Manager',
      'category': 'People',
      'route': '/employee/emp_mahmud',
    },
    {
      'title': 'Md. Yeapas',
      'subtitle': 'People · Senior Software Engineer',
      'category': 'People',
      'route': '/employee/emp_yeapas',
    },
    {
      'title': 'Send Enterprise proposal',
      'subtitle': 'Task · High Priority · Due Today',
      'category': 'Tasks',
      'route': '/tasks/t-001',
    },
    {
      'title': 'Demo call preparation',
      'subtitle': 'Task · High Priority · In Progress',
      'category': 'Tasks',
      'route': '/tasks/t-002',
    },
    {
      'title': 'NEC-127 Push notifications not received',
      'subtitle': 'Issue · Resolved · Mobile App',
      'category': 'Issues',
      'route': '/issues',
    },
    {
      'title': 'NEC-132 Hotel website booking form not submitting',
      'subtitle': 'Issue · Urgent · Website',
      'category': 'Issues',
      'route': '/issues',
    },
    {
      'title': 'NEC-133 Restaurant order status not updating',
      'subtitle': 'Issue · High · Backend',
      'category': 'Issues',
      'route': '/issues',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _removeRecentSearch(String item) {
    setState(() {
      _recentSearches.remove(item);
    });
  }

  void _selectSearchTerm(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Leads':
        return CupertinoIcons.person_2_fill;
      case 'People':
        return CupertinoIcons.person_fill;
      case 'Tasks':
        return CupertinoIcons.checkmark_square_fill;
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

    final matchingResults = query.isEmpty
        ? <Map<String, String>>[]
        : _allSearchableItems.where((item) {
            final titleMatch = item['title']!.toLowerCase().contains(query);
            final subtitleMatch =
                item['subtitle']!.toLowerCase().contains(query);
            final catMatch = item['category']!.toLowerCase().contains(query);
            return StaffAccessStore.instance.canOpen(item['route']!) &&
                (titleMatch || subtitleMatch || catMatch);
          }).toList();

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
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
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
              const SizedBox(height: 20),
              if (query.isNotEmpty) ...[
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
                        final cat = item['category']!;

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
                                item['title']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                item['subtitle']!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: nec.textTertiary,
                                ),
                              ),
                              trailing: Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: nec.textTertiary,
                              ),
                              onTap: () {
                                _navigateTo(item['route']!);
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
                    if (StaffAccessStore.instance.canOpen('/team'))
                      _buildBrowseCard(
                        nec,
                        title: 'People',
                        icon: CupertinoIcons.person_fill,
                        iconColor: AppColors.leadContacted,
                        onTap: () => _navigateTo('/team'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/tasks'))
                      _buildBrowseCard(
                        nec,
                        title: 'Tasks',
                        icon: CupertinoIcons.checkmark_square_fill,
                        iconColor: AppColors.brandLight,
                        onTap: () => _navigateTo('/tasks'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/issues'))
                      _buildBrowseCard(
                        nec,
                        title: 'Issues',
                        icon: CupertinoIcons.exclamationmark_circle_fill,
                        iconColor: AppColors.error,
                        onTap: () => _navigateTo('/issues'),
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
