import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../attendance/presentation/widgets/attendance_home_card.dart';
import '../../../attendance/presentation/widgets/attendance_ui.dart';
import 'lead_snapshot_grid.dart';
import 'leads_needing_action_section.dart';
import 'my_work_section.dart';
import 'needs_attention_section.dart';
import 'recent_activity_section.dart';
import 'today_schedule_section.dart';

class RoleWorkspace extends StatelessWidget {
  const RoleWorkspace({super.key});
  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final session = DemoSession.instance;
    return AttendanceCard(
        child: Row(children: [
      Icon(
          session.isAdmin
              ? CupertinoIcons.shield_fill
              : CupertinoIcons.person_fill,
          color: nec.brand,
          size: 28),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${session.roleLabel} Workspace',
            style: TextStyle(
                color: nec.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(session.email,
            style: TextStyle(color: nec.textSecondary, fontSize: 12)),
      ])),
      CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.push(session.isAdmin ? '/administration' : '/my-access'),
          child:
              Icon(CupertinoIcons.chevron_right, color: nec.brand, size: 18)),
    ]));
  }
}

class StaffHomeContent extends StatelessWidget {
  const StaffHomeContent({super.key});

  static const double _gap = 14;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: StaffAccessStore.instance,
      builder: (context, _) {
        final access = StaffAccessStore.instance;
        bool can(StaffPermission p) => access.allows(p);
        final showSnapshot = StaffSnapshotGrid.hasAny;
        final showAttention = can(StaffPermission.followUps);
        final showToday =
            can(StaffPermission.followUps) || can(StaffPermission.visits);
        final showLeadActions =
            can(StaffPermission.leads) && can(StaffPermission.followUps);
        final showWork = can(StaffPermission.tasks) || can(StaffPermission.issues);
        final showActivity = can(StaffPermission.activity);
        final hasAnything = can(StaffPermission.attendance) ||
            showSnapshot ||
            showToday ||
            showWork ||
            showActivity ||
            can(StaffPermission.leads);

        Widget section(String title, Widget child,
                {String? action, VoidCallback? onTap}) =>
            Padding(
              padding: const EdgeInsets.only(top: _gap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SectionHeader(
                        title: title, actionTitle: action, onActionTap: onTap),
                  ),
                  child,
                ],
              ),
            );

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (can(StaffPermission.attendance)) ...[
            const SizedBox(height: 6),
            const AttendanceHomeCard(),
          ],
          if (showSnapshot)
            section(
                'MY OVERVIEW',
                const StaffSnapshotGrid(),
                action: can(StaffPermission.leads) ? 'All Leads' : null,
                onTap: () => context.go('/leads')),
          if (showAttention)
            section('NEEDS ATTENTION', const NeedsAttentionSection(staff: true)),
          if (showToday)
            section(
                'TODAY', const TodayScheduleSection(staff: true),
                action: can(StaffPermission.tasks) ? 'See All' : null,
                onTap: () => context.go('/tasks')),
          if (showLeadActions)
            section('LEADS NEEDING ACTION', const LeadsNeedingActionSection(),
                action: 'View All', onTap: () => context.go('/leads')),
          if (showWork)
            section(
                'MY WORK',
                MyWorkSection(
                    showTasks: can(StaffPermission.tasks),
                    showIssues: can(StaffPermission.issues))),
          if (showActivity)
            section('RECENT ACTIVITY', const RecentActivitySection(),
                action: 'View All', onTap: () => context.push('/activity')),
          if (!hasAnything)
            const Padding(
              padding: EdgeInsets.only(top: _gap),
              child: AttendanceEmpty(
                  title: 'No modules assigned',
                  message:
                      'Your administrator has not enabled any modules for your staff role yet.',
                  icon: CupertinoIcons.lock),
            ),
          const SizedBox(height: 96),
        ]);
      });
}
