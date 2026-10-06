import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/theme/app_colors.dart';
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
    final access = StaffAccessStore.instance;
    final tiles = <Widget>[
      if (access.allows(StaffPermission.leads))
        _tap(
            context,
            '/leads',
            const LeadMetricTile(
              value: '4',
              label: 'My Leads',
              subtitle: '+1 today',
              accentColor: AppColors.leadContacted,
              icon: CupertinoIcons.person_2_fill,
            )),
      if (access.allows(StaffPermission.followUps))
        _tap(
            context,
            '/follow-ups',
            const LeadMetricTile(
              value: '6',
              label: 'Follow-up Due',
              subtitle: '2 overdue',
              accentColor: AppColors.warning,
              icon: CupertinoIcons.clock_fill,
            )),
      if (access.allows(StaffPermission.visits))
        _tap(
            context,
            '/visits',
            const LeadMetricTile(
              value: '2',
              label: 'Visits Today',
              subtitle: 'Scheduled',
              accentColor: AppColors.leadVisit,
              icon: CupertinoIcons.map_pin_ellipse,
            )),
      if (access.allows(StaffPermission.tasks))
        _tap(
            context,
            '/tasks',
            const LeadMetricTile(
              value: '3',
              label: 'My Tasks',
              subtitle: '2 due today',
              accentColor: AppColors.brandLight,
              icon: CupertinoIcons.checkmark_square_fill,
            )),
    ];
    const height = 88.0;
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      final pair = tiles.skip(i).take(2).toList();
      rows.add(SizedBox(
        height: height,
        child: Row(children: [
          Expanded(child: pair[0]),
          if (pair.length > 1) ...[
            const SizedBox(width: 8),
            Expanded(child: pair[1]),
          ],
        ]),
      ));
    }
    return Column(children: rows);
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.95,
      children: const [
        LeadMetricTile(
          value: '3',
          label: 'New',
          subtitle: '+3 today',
          accentColor: AppColors.brandLight,
          icon: CupertinoIcons.person_add_solid,
        ),
        LeadMetricTile(
          value: '4',
          label: 'My Leads',
          subtitle: 'Active',
          accentColor: AppColors.leadContacted,
          icon: CupertinoIcons.person_2_fill,
        ),
        LeadMetricTile(
          value: '6',
          label: 'Follow-up Due',
          subtitle: '2 overdue',
          accentColor: AppColors.warning,
          icon: CupertinoIcons.clock_fill,
        ),
        LeadMetricTile(
          value: '2',
          label: 'Visits Today',
          subtitle: 'Scheduled',
          accentColor: AppColors.leadVisit,
          icon: CupertinoIcons.map_pin_ellipse,
        ),
      ],
    );
  }
}
