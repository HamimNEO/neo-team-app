import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';
import '../../attendance/data/attendance_clock.dart';
import '../../attendance/data/attendance_store.dart';
import '../../meals/data/meal_store.dart';
import 'package:intl/intl.dart';
import 'widgets/role_workspace.dart';
import '../../../core/widgets/section_header.dart';
import '../../attendance/presentation/widgets/attendance_admin_home_card.dart';
import '../../meals/presentation/widgets/lunch_entry.dart';
import 'widgets/home_greeting_bar.dart';
import 'widgets/home_skeleton_loader.dart';
import 'widgets/lead_snapshot_grid.dart';
import 'widgets/leads_needing_action_section.dart';
import 'widgets/my_work_section.dart';
import 'widgets/needs_attention_section.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/today_schedule_section.dart';
import '../../leads/data/lead_store.dart';
import '../../tasks/data/work_item_store.dart';
import '../../more/data/notification_store.dart';
import '../../team/data/employee_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _sessionToken;

  bool get _hasDashboard =>
      WorkItemStore.instance.hasOverview ||
      (WorkItemStore.instance.hasData && LeadStore.instance.hasData);

  @override
  void initState() {
    super.initState();
    _sessionToken = DemoSession.instance.accessToken;
    _isLoading = !_hasDashboard;
    LeadStore.instance.addListener(_refresh);
    NotificationStore.instance.addListener(_refresh);
    WorkItemStore.instance.addListener(_refresh);
    EmployeeStore.instance.addListener(_refresh);
    StaffAccessStore.instance.addListener(_refresh);
    AttendanceStore.instance.addListener(_refresh);
    MealStore.instance.addListener(_refresh);
    DemoSession.instance.addListener(_sessionChanged);
    _loadData();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        if (_hasDashboard) _isLoading = false;
      });
    }
  }

  void _sessionChanged() {
    final token = DemoSession.instance.accessToken;
    if (!mounted || token == _sessionToken) return;
    _sessionToken = token;
    if (token != null) {
      setState(() => _isLoading = !_hasDashboard);
      _loadData();
    }
  }

  @override
  void dispose() {
    LeadStore.instance.removeListener(_refresh);
    NotificationStore.instance.removeListener(_refresh);
    WorkItemStore.instance.removeListener(_refresh);
    EmployeeStore.instance.removeListener(_refresh);
    StaffAccessStore.instance.removeListener(_refresh);
    AttendanceStore.instance.removeListener(_refresh);
    MealStore.instance.removeListener(_refresh);
    DemoSession.instance.removeListener(_sessionChanged);
    super.dispose();
  }

  Future<void> _loadData({bool force = false}) async {
    final token = DemoSession.instance.accessToken;
    await Future.wait([
      StaffAccessStore.instance.load(force: force),
      LeadStore.instance.load(force: force, preferCache: !force),
      WorkItemStore.instance.load(force: force, preferCache: !force),
      EmployeeStore.instance.load(preferCache: !force),
      AttendanceStore.instance.load(forceRemote: force),
      MealStore.instance.load(),
    ]);
    if (!mounted || token != DemoSession.instance.accessToken) return;
    setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    await _loadData(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Scaffold(
      backgroundColor: nec.bg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: nec.brand,
          backgroundColor: nec.surface,
          child: _isLoading
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child:
                      HomeSkeletonLoader(isAdmin: DemoSession.instance.isAdmin),
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: HomeGreetingBar(
                        userName: DemoSession.instance.user?.name ?? '',
                        userInitials: EmployeeStore
                            .instance.currentEmployee.avatarInitials,
                        dateString: DateFormat('EEEE, MMMM d')
                            .format(AttendanceClock.today),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DemoSession.instance.isAdmin
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  const AttendanceAdminHomeCard(),
                                  const SizedBox(height: 14),
                                  const LunchEntry(administrator: true),
                                  const SizedBox(height: 14),
                                  SectionHeader(
                                    title: 'LEADS',
                                    actionTitle: 'All Leads',
                                    onActionTap: () => context.go('/leads'),
                                  ),
                                  const SizedBox(height: 6),
                                  const LeadSnapshotGrid(),
                                  const SizedBox(height: 14),
                                  const SectionHeader(title: 'NEEDS ATTENTION'),
                                  const SizedBox(height: 6),
                                  const NeedsAttentionSection(),
                                  const SizedBox(height: 14),
                                  SectionHeader(
                                    title: 'TODAY',
                                    actionTitle: 'See All',
                                    onActionTap: () => context.go('/tasks'),
                                  ),
                                  const SizedBox(height: 6),
                                  const TodayScheduleSection(),
                                  const SizedBox(height: 14),
                                  SectionHeader(
                                    title: 'LEADS NEEDING ACTION',
                                    actionTitle: 'View All',
                                    onActionTap: () => context.go('/leads'),
                                  ),
                                  const SizedBox(height: 6),
                                  const LeadsNeedingActionSection(),
                                  const SizedBox(height: 14),
                                  const SectionHeader(title: 'TEAM WORK'),
                                  const SizedBox(height: 6),
                                  const MyWorkSection(),
                                  const SizedBox(height: 14),
                                  SectionHeader(
                                    title: 'RECENT ACTIVITY',
                                    actionTitle: 'View All',
                                    onActionTap: () =>
                                        context.push('/activity'),
                                  ),
                                  const SizedBox(height: 6),
                                  const RecentActivitySection(),
                                  const SizedBox(height: 96),
                                ],
                              )
                            : const StaffHomeContent(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
