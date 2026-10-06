import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mock_employees.dart';
import 'widgets/create_department_sheet.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  late List<DepartmentItem> _departments;

  @override
  void initState() {
    super.initState();
    _departments = List.from(mockDepartments);
  }

  void _openCreateDepartmentSheet() async {
    final result = await showModalBottomSheet<DepartmentItem>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CreateDepartmentSheet(),
    );
    if (result != null) {
      setState(() {
        _departments.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeCount = _departments.where((d) => d.status == 'Active').length;
    final totalMembers =
        _departments.fold<int>(0, (sum, d) => sum + d.memberCount);
    final totalTeams = _departments.fold<int>(0, (sum, d) => sum + d.teamCount);

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
                  'Departments',
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
                onPressed: _openCreateDepartmentSheet,
                child: Text(
                  '+ New',
                  style: TextStyle(
                    color: nec.brand,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
              Row(
                children: [
                  _buildStatCard(
                    nec,
                    isDark,
                    '$activeCount',
                    'Active',
                    AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    nec,
                    isDark,
                    '$totalMembers',
                    'Total Members',
                    AppColors.brandLight,
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    nec,
                    isDark,
                    '$totalTeams',
                    'Total Teams',
                    AppColors.leadContacted,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'ACTIVE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(_departments.length, (index) {
                    final dept = _departments[index];
                    final isLast = index == _departments.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              'Lead: ${dept.leadName} · ${dept.memberCount} members · ${dept.teamCount} ${dept.teamCount == 1 ? 'team' : 'teams'}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: nec.textTertiary,
                              ),
                            ),
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
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    NecColors nec,
    bool isDark,
    String value,
    String label,
    Color valueColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
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
    );
  }
}
