import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/demo_session.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/presentation/widgets/profile_tab_bar.dart';
import '../data/employee_store.dart';
import '../domain/models/employee.dart';
import 'widgets/employee_action_sheet.dart';
import 'widgets/employee_activity_tab.dart';
import 'widgets/employee_more_tab.dart';
import 'widgets/employee_details_tab.dart';
import 'widgets/employee_salary_tab.dart';
import 'widgets/employee_profile_header.dart';
import 'widgets/employee_work_tab.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final String employeeId;

  const EmployeeProfileScreen({super.key, required this.employeeId});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
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

  void _openActionSheet(BuildContext context, Employee employee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EmployeeActionSheet(employee: employee),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final employee = EmployeeStore.instance.byId(widget.employeeId);
    if (employee == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Employee unavailable')),
          body: const Center(child: Text('This employee could not be found.')));
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
                  employee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                onPressed: DemoSession.instance.isAdmin
                    ? () => _openActionSheet(context, employee)
                    : null,
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              EmployeeProfileHeader(employee: employee),
              ProfileTabBar(
                selectedIndex: _selectedTabIndex,
                tabs: const ['Overview', 'Salary', 'Work', 'Activity', 'More'],
                onTabSelected: (index) {
                  setState(() => _selectedTabIndex = index);
                },
              ),
              <Widget>[
                EmployeeDetailsTab(employee: employee),
                EmployeeSalaryTab(employee: employee),
                EmployeeWorkTab(employee: employee),
                const EmployeeActivityTab(),
                EmployeeMoreTab(employee: employee),
              ][_selectedTabIndex],
            ],
          ),
        ),
      ),
    );
  }
}
