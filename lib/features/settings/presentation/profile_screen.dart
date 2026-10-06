import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/profile_activity_tab.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_more_tab.dart';
import '../../team/data/employee_store.dart';
import '../../team/presentation/widgets/employee_details_tab.dart';
import '../../team/presentation/widgets/employee_salary_tab.dart';
import 'widgets/profile_tab_bar.dart';
import 'widgets/profile_work_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    EmployeeStore.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    EmployeeStore.instance.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final employee = EmployeeStore.instance.currentEmployee;

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
                      CupertinoIcons.back,
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
                  'My Profile',
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
                onPressed: () => context.push('/edit-profile'),
                child: Icon(
                  CupertinoIcons.square_pencil,
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(
                  employee: employee,
                  onEditTap: () => context.push('/edit-profile')),
              ProfileTabBar(
                tabs: const ['Overview', 'Salary', 'Work', 'Activity', 'More'],
                selectedIndex: _selectedTabIndex,
                onTabSelected: (index) {
                  setState(() => _selectedTabIndex = index);
                },
              ),
              <Widget>[
                EmployeeDetailsTab(employee: employee),
                EmployeeSalaryTab(employee: employee),
                const ProfileWorkTab(),
                const ProfileActivityTab(),
                ProfileMoreTab(employee: employee),
              ][_selectedTabIndex],
            ],
          ),
        ),
      ),
    );
  }
}
