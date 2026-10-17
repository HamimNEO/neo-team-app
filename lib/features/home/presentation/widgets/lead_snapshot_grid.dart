import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../leads/data/lead_store.dart';
import '../../../team/data/employee_store.dart';
import '../../../tasks/data/work_item_store.dart';
import 'lead_metric_tile.dart';

/// Summary cards for staff users. Only modules allowed by the admin appear.
class StaffSnapshotGrid extends StatelessWidget {
  const StaffSnapshotGrid({super.key});

  static List<StaffPermission> get permissions => const [
        StaffPermission.leads,
        StaffPermission.followUps,
        StaffPermission.visits,
        StaffPermission.tasks,
      ];

  static bool get hasAny =>
      permissions.any((p) => StaffAccessStore.instance.allows(p));

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge(
          [LeadStore.instance, WorkItemStore.instance, EmployeeStore.instance]),
      builder: (context, _) {
        final access = StaffAccessStore.instance;
        final summary = WorkItemStore.instance.overview.summary;
        final work = WorkItemStore.instance;
        final myLeadsCount = work.hasOverview
            ? summary.leads.toString()
            : LeadStore.instance.hasData
                ? LeadStore.instance.leads
                    .where((l) =>
                        !['won', 'lost'].contains(l.status.toLowerCase()))
                    .length
                    .toString()
                : '—';
        final followUpsCount = work.hasOverview
            ? summary.dueFollowups.toString()
            : work.hasData
                ? work.dueFollowUps.toString()
                : '—';
        final visitsCount = work.hasOverview
            ? summary.todayVisits.toString()
            : work.hasData
                ? work.todayVisits.toString()
                : '—';
        final tasksCount = work.hasOverview
            ? summary.openTasks.toString()
            : work.hasData
                ? work.openTasks.toString()
                : '—';

        final tiles = <Widget>[
          if (access.allows(StaffPermission.leads))
            _tap(
                context,
                '/leads',
                LeadMetricTile(
                  value: myLeadsCount,
                  label: 'My Leads',
                  subtitle: 'Active',
                  accentColor: const Color(0xFF8B5CF6),
                  icon: CupertinoIcons.person_2_fill,
                )),
          if (access.allows(StaffPermission.followUps))
            _tap(
                context,
                '/follow-ups',
                LeadMetricTile(
                  value: followUpsCount,
                  label: 'Follow-up Due',
                  subtitle: 'Due',
                  accentColor: const Color(0xFFF59E0B),
                  icon: CupertinoIcons.clock_fill,
                )),
          if (access.allows(StaffPermission.visits))
            _tap(
                context,
                '/visits',
                LeadMetricTile(
                  value: visitsCount,
                  label: 'Visits Today',
                  subtitle: 'Scheduled',
                  accentColor: const Color(0xFFEF4444),
                  icon: CupertinoIcons.location_fill,
                )),
          if (access.allows(StaffPermission.tasks))
            _tap(
                context,
                '/tasks',
                LeadMetricTile(
                  value: tasksCount,
                  label: 'My Tasks',
                  subtitle: 'Open',
                  accentColor: const Color(0xFF007AFF),
                  icon: CupertinoIcons.checkmark_square_fill,
                )),
        ];

        const double tileHeight = 110.0;
        final rows = <Widget>[];
        for (var i = 0; i < tiles.length; i += 2) {
          if (i > 0) rows.add(const SizedBox(height: 10));
          final pair = tiles.skip(i).take(2).toList();
          rows.add(SizedBox(
            height: tileHeight,
            child: Row(children: [
              Expanded(child: pair[0]),
              if (pair.length > 1) ...[
                const SizedBox(width: 10),
                Expanded(child: pair[1]),
              ],
            ]),
          ));
        }

        return Container(
          decoration: BoxDecoration(
            color: nec.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : nec.separator.withValues(alpha: 0.18),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.035),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MY OVERVIEW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: nec.textTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (access.allows(StaffPermission.leads))
                    GestureDetector(
                      onTap: () => context.go('/leads'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'All Leads',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: nec.brand,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 14,
                            color: nec.brand,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Column(children: rows),
            ],
          ),
        );
      },
    );
  }

  Widget _tap(BuildContext context, String route, Widget child) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => route == '/leads' || route == '/tasks'
            ? context.go(route)
            : context.push(route),
        child: child,
      );
}

class LeadSnapshotGrid extends StatelessWidget {
  const LeadSnapshotGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [LeadStore.instance, WorkItemStore.instance, EmployeeStore.instance]),
      builder: (context, _) {
        final summary = WorkItemStore.instance.overview.summary;
        final leads = LeadStore.instance.leads;

        final newCount = LeadStore.instance.hasData
            ? leads
                .where((l) => l.status.toLowerCase() == 'new')
                .length
                .toString()
            : summary.newLeads > 0
                ? summary.newLeads.toString()
                : '0';

        final employeeCount = EmployeeStore.instance.hasData
            ? EmployeeStore.instance.employees.length.toString()
            : '—';
        final work = WorkItemStore.instance;
        final followUpsCount = work.hasOverview
            ? summary.dueFollowups.toString()
            : work.hasData
                ? work.dueFollowUps.toString()
                : '—';
        final visitsCount = work.hasOverview
            ? summary.todayVisits.toString()
            : work.hasData
                ? work.todayVisits.toString()
                : '—';

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            LeadMetricTile(
              value: newCount,
              label: 'New',
              subtitle: 'New leads',
              accentColor: AppColors.brandLight,
              icon: CupertinoIcons.person_add_solid,
            ),
            LeadMetricTile(
              value: employeeCount,
              label: 'Employees',
              subtitle: 'Team members',
              accentColor: AppColors.leadContacted,
              icon: CupertinoIcons.person_2_fill,
            ),
            LeadMetricTile(
              value: followUpsCount,
              label: 'Follow-up Due',
              subtitle: 'Due',
              accentColor: AppColors.warning,
              icon: CupertinoIcons.clock_fill,
            ),
            LeadMetricTile(
              value: visitsCount,
              label: 'Visits Today',
              subtitle: 'Scheduled',
              accentColor: AppColors.leadVisit,
              icon: CupertinoIcons.location_fill,
            ),
          ],
        );
      },
    );
  }
}
