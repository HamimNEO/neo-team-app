import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../data/mock_employees.dart';
import '../data/employee_store.dart';
import '../domain/models/employee.dart';
import 'widgets/employee_filter_sheet.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String _selectedTab = 'Employees';

  bool _isSearching = false;
  final _searchController = TextEditingController();

  String? _filterDepartment;
  String? _filterRole;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    EmployeeStore.instance.addListener(_refresh);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    EmployeeStore.instance.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EmployeeFilterSheet(
        selectedDepartment: _filterDepartment,
        selectedRole: _filterRole,
        selectedStatus: _filterStatus,
        onApply: (department, role, status) {
          setState(() {
            _filterDepartment = department;
            _filterRole = role;
            _filterStatus = status;
          });
        },
      ),
    );
  }

  List<Employee> _getFilteredEmployees() {
    return mockEmployees.where((e) {
      if (_filterDepartment != null && _filterDepartment!.isNotEmpty) {
        if (!e.department
            .toLowerCase()
            .contains(_filterDepartment!.toLowerCase())) {
          return false;
        }
      }
      if (_filterRole != null && _filterRole!.isNotEmpty) {
        if (e.systemRole.toLowerCase() != _filterRole!.toLowerCase()) {
          return false;
        }
      }
      if (_filterStatus != null && _filterStatus!.isNotEmpty) {
        if (e.status.toLowerCase() != _filterStatus!.toLowerCase()) {
          return false;
        }
      }

      final query = _searchController.text.trim().toLowerCase();
      if (_isSearching && query.isNotEmpty) {
        final nameMatch = e.name.toLowerCase().contains(query);
        final desigMatch = e.designation.toLowerCase().contains(query);
        final deptMatch = e.department.toLowerCase().contains(query);
        if (!nameMatch && !desigMatch && !deptMatch) return false;
      }

      return true;
    }).toList();
  }

  List<TeamGroup> _getFilteredTeams() {
    final query = _searchController.text.trim().toLowerCase();
    if (!_isSearching || query.isEmpty) return mockTeams;
    return mockTeams.where((t) {
      return t.name.toLowerCase().contains(query) ||
          t.leadName.toLowerCase().contains(query) ||
          t.department.toLowerCase().contains(query);
    }).toList();
  }

  List<DepartmentItem> _getFilteredDepartments() {
    final query = _searchController.text.trim().toLowerCase();
    if (!_isSearching || query.isEmpty) return mockDepartments;
    return mockDepartments.where((d) {
      return d.name.toLowerCase().contains(query) ||
          d.leadName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredEmployees = _getFilteredEmployees();
    final filteredTeams = _getFilteredTeams();
    final filteredDepartments = _getFilteredDepartments();

    final hasActiveFilter = _filterDepartment != null ||
        _filterRole != null ||
        _filterStatus != null;

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
                                  hintText: 'Search team...',
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
                        'Team',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: nec.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openFilterSheet,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: hasActiveFilter
                              ? AppColors.brandLight.withValues(alpha: 0.2)
                              : nec.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 18,
                          color: hasActiveFilter
                              ? AppColors.brandLight
                              : nec.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                      onTap: () => context.push('/add-employee'),
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
                    nec, isDark, '15', 'Employees', AppColors.brandLight, () {
                  setState(() => _selectedTab = 'Employees');
                }),
                const SizedBox(width: 8),
                _buildStatCard(nec, isDark, '14', 'Active', AppColors.success,
                    () {
                  setState(() => _selectedTab = 'Employees');
                }),
                const SizedBox(width: 8),
                _buildStatCard(
                    nec, isDark, '4', 'Teams', AppColors.leadContacted, () {
                  setState(() => _selectedTab = 'Teams');
                }),
                const SizedBox(width: 8),
                _buildStatCard(
                    nec, isDark, '5', 'Departments', AppColors.warning, () {
                  setState(() => _selectedTab = 'Departments');
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSubTabBar(nec),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildTabContent(
                nec,
                filteredEmployees,
                filteredTeams,
                filteredDepartments,
              ),
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

  Widget _buildSubTabBar(NecColors nec) {
    final tabs = ['Employees', 'Teams', 'Departments'];
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
                      color:
                          isSelected ? AppColors.brandLight : nec.textTertiary,
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

  Widget _buildTabContent(
    NecColors nec,
    List<Employee> employees,
    List<TeamGroup> teams,
    List<DepartmentItem> departments,
  ) {
    if (_selectedTab == 'Employees') {
      if (employees.isEmpty) return _buildEmptyState(nec, 'employees');
      return Material(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(employees.length, (index) {
            final emp = employees[index];
            final isLast = index == employees.length - 1;

            return Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: NecAvatar(
                    initials: emp.avatarInitials,
                    photoBase64: emp.photoBase64,
                    size: 38,
                  ),
                  title: Text(
                    emp.name,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${emp.designation}\n${emp.department}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: nec.textTertiary,
                      height: 1.3,
                    ),
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: () => context.push('/employee/${emp.id}'),
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
      );
    } else if (_selectedTab == 'Teams') {
      if (teams.isEmpty) return _buildEmptyState(nec, 'teams');
      return Material(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(teams.length, (index) {
            final team = teams[index];
            final isLast = index == teams.length - 1;

            return Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.leadContacted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_2_fill,
                      color: AppColors.leadContacted,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    team.name,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        'Lead: ${team.leadName}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: nec.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${mockEmployees.where((employee) => employee.team == team.name).length} Members · ${team.department}',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: () => context.push('/team-details/${team.id}'),
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
      );
    } else {
      if (departments.isEmpty) return _buildEmptyState(nec, 'departments');
      return Material(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(departments.length, (index) {
            final dept = departments[index];
            final isLast = index == departments.length - 1;

            return Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: dept.iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CupertinoIcons.briefcase_fill,
                      color: dept.iconColor,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    dept.name,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        dept.leadName,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: nec.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${dept.memberCount} Employees',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: () => context.push('/department/${dept.id}'),
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
      );
    }
  }

  Widget _buildEmptyState(NecColors nec, String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.brandLight.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.person_3_fill,
                size: 32,
                color: AppColors.brandLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No $type match "${_searchController.text.trim()}". Try clearing your search query.',
              textAlign: TextAlign.center,
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
