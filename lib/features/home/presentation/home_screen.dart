import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/demo_session.dart';
import '../../attendance/data/attendance_clock.dart';
import 'package:intl/intl.dart';
import 'widgets/role_workspace.dart';
import '../../../core/widgets/section_header.dart';
import '../../attendance/presentation/widgets/attendance_home_card.dart';
import 'widgets/home_greeting_bar.dart';
import 'widgets/home_skeleton_loader.dart';
import 'widgets/lead_snapshot_grid.dart';
import 'widgets/leads_needing_action_section.dart';
import 'widgets/my_work_section.dart';
import 'widgets/needs_attention_section.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/today_schedule_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Scaffold(
      backgroundColor: nec.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: nec.brand,
          backgroundColor: nec.surface,
          child: _isLoading
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: HomeSkeletonLoader(
                      isAdmin: DemoSession.instance.isAdmin),
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: HomeGreetingBar(
                        userName: 'Shahina',
                        userInitials: 'MA',
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
                                  const AttendanceHomeCard(),
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
                                  const SectionHeader(title: 'MY WORK'),
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
