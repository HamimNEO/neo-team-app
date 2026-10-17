import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/demo_session.dart';
import '../../attendance/data/attendance_store.dart';
import '../../leads/data/lead_store.dart';
import '../../meals/data/meal_store.dart';
import '../data/system_settings_store.dart';
import '../data/profile_store.dart';
import '../domain/models/account_profile.dart';
import 'widgets/admin_profile_tabs.dart';
import 'widgets/profile_activity_tab.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_more_tab.dart';
import '../../team/data/employee_store.dart';
import '../../team/domain/models/employee.dart';
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
  late String _ownerId;
  late bool _administrator;

  @override
  void initState() {
    super.initState();
    _ownerId = DemoSession.instance.employeeId;
    _administrator = DemoSession.instance.isAdmin;
    EmployeeStore.instance.addListener(_refresh);
    SystemSettingsStore.instance.addListener(_refresh);
    ProfileStore.instance.addListener(_refresh);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (DemoSession.instance.isAdmin) {
      await Future.wait([
        ProfileStore.instance.load(),
        AttendanceStore.instance.load(),
        MealStore.instance.load(),
        LeadStore.instance.load(),
      ]);
    } else {
      await Future.wait([
        ProfileStore.instance.load(),
        SystemSettingsStore.instance.load(),
      ]);
    }
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      if (_ownerId != DemoSession.instance.employeeId ||
          _administrator != DemoSession.instance.isAdmin) {
        _selectedTabIndex = 0;
        _ownerId = DemoSession.instance.employeeId;
        _administrator = DemoSession.instance.isAdmin;
      }
    });
  }

  @override
  void dispose() {
    EmployeeStore.instance.removeListener(_refresh);
    SystemSettingsStore.instance.removeListener(_refresh);
    ProfileStore.instance.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    if (!DemoSession.instance.signedIn) return const SizedBox.shrink();
    final administrator = DemoSession.instance.isAdmin;
    final accountProfile = ProfileStore.instance.profile ??
        (DemoSession.instance.user == null
            ? null
            : AccountProfile.fromAuthUser(DemoSession.instance.user!));
    final initialEmployee = accountProfile?.employeeProfile ??
        EmployeeStore.instance.currentEmployee;
    final storeEmp = EmployeeStore.instance.byId(initialEmployee.id);
    final employee = storeEmp != null
        ? Employee.fromJson({
            ...initialEmployee.toJson(),
            'employmentType': storeEmp.employmentType,
            'probationStartDate': storeEmp.probationStartDate,
            'probationEndDate': storeEmp.probationEndDate,
            'agreementPdfName': storeEmp.agreementPdfName,
            'agreementPdfUrl': storeEmp.agreementPdfUrl,
            'agreementPdfBase64': storeEmp.agreementPdfBase64,
            'agreementPdfSizeBytes': storeEmp.agreementPdfSizeBytes,
          })
        : initialEmployee;
    final tabs = administrator
        ? const ['Overview', 'Manage', 'Activity', 'More']
        : const ['Overview', 'Salary', 'Work', 'Activity', 'More'];
    final pages = administrator
        ? <Widget>[
            AdminProfileOverviewTab(profile: accountProfile),
            const AdminProfileManagementTab(),
            AdminProfileActivityTab(employeeId: employee.id),
            ProfileMoreTab(employee: employee),
          ]
        : <Widget>[
            EmployeeDetailsTab(employee: employee),
            EmployeeSalaryTab(employee: employee),
            ProfileWorkTab(work: accountProfile?.work ?? const {}),
            ProfileActivityTab(
                activities: accountProfile?.activity ?? const []),
            ProfileMoreTab(employee: employee),
          ];

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
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/more'),
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
              if (!administrator)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.push('/edit-profile'),
                  child: Icon(
                    CupertinoIcons.square_pencil,
                    size: 20,
                    color: nec.brand,
                  ),
                )
              else
                const SizedBox(width: 44, height: 44),
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
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                if (ProfileStore.instance.loading)
                  const LinearProgressIndicator(minHeight: 2),
                if (ProfileStore.instance.loadError != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      Expanded(
                          child: Text(ProfileStore.instance.loadError!,
                              style: TextStyle(
                                  color: nec.textSecondary, fontSize: 12))),
                      TextButton(
                          onPressed: _loadProfileData,
                          child: const Text('Retry')),
                    ]),
                  ),
                ProfileHeader(
                    employee: employee,
                    administrator: administrator,
                    profile: accountProfile,
                    onEditTap: administrator
                        ? null
                        : () => context.push('/edit-profile')),
                ProfileTabBar(
                  tabs: tabs,
                  selectedIndex: _selectedTabIndex,
                  onTabSelected: (index) {
                    setState(() => _selectedTabIndex = index);
                  },
                ),
                pages[_selectedTabIndex < pages.length ? _selectedTabIndex : 0],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
