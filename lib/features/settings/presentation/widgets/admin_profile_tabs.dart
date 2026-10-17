import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/data/attendance_clock.dart';
import '../../../attendance/data/attendance_store.dart';
import '../../../attendance/domain/models/attendance_models.dart';
import '../../../attendance/presentation/widgets/attendance_ui.dart';
import '../../../leads/data/lead_store.dart';
import '../../../meals/data/meal_store.dart';
import '../../../meals/domain/models/lunch_preference.dart';
import '../../../team/data/employee_store.dart';
import '../../../team/presentation/widgets/employee_details_section.dart';
import '../../domain/models/account_profile.dart';

class AdminProfileOverviewTab extends StatelessWidget {
  final AccountProfile? profile;

  const AdminProfileOverviewTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (!DemoSession.instance.isAdmin) return const SizedBox.shrink();
    final value = profile;
    if (value == null) return const SizedBox.shrink();
    Widget section(String title, List<(String, String?)> rows) {
      final available = rows
          .where((row) => row.$2?.trim().isNotEmpty ?? false)
          .map((row) => (row.$1, row.$2!))
          .toList();
      return available.isEmpty
          ? const SizedBox.shrink()
          : EmployeeDetailsSection(title: title, rows: available);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(children: [
        section('Administrator Account', [
          ('Name', value.name),
          ('Login Email', value.email),
          ('System Role', value.roleLabel),
          ('Access', value.accessLabel),
          ('Account Status', value.statusLabel),
        ]),
        section(
            'Contact', [('Phone', value.phone), ('Address', value.address)]),
        section('Organization', [('Name', value.organization)]),
        section('Employee Information', [
          ('Employee Code', value.employeeCode),
          ('Designation', value.designation),
          ('Department', value.department),
          ('Team', value.team),
        ]),
      ]),
    );
  }
}

class AdminProfileManagementTab extends StatelessWidget {
  const AdminProfileManagementTab({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([
          EmployeeStore.instance,
          LeadStore.instance,
          AttendanceStore.instance,
          MealStore.instance,
        ]),
        builder: (context, _) {
          if (!DemoSession.instance.isAdmin) return const SizedBox.shrink();
          final nec = Theme.of(context).extension<NecColors>()!;
          final employees = EmployeeStore.instance;
          final attendance = AttendanceStore.instance;
          final active = employees.staffEmployees
              .where((staff) => staff.status == 'Active');
          final day = AttendanceClock.key(AttendanceClock.today);
          final pending = attendance.allRequests
              .where((request) =>
                  request.status == AttendanceRequestStatus.pending &&
                  employees.isStaffEmployee(request.employeeId))
              .length;
          final lunches = active
              .where((staff) =>
                  MealStore.instance.statusFor(staff.id, day) ==
                  LunchStatus.receiving)
              .length;
          final actions = <(IconData, Color, String, String, String)>[
            (
              CupertinoIcons.person_2_fill,
              const Color(0xFF007AFF),
              'Staff Directory',
              'Manage employees & profiles',
              '/team',
            ),
            (
              CupertinoIcons.person_2_square_stack_fill,
              const Color(0xFFFF9500),
              'Leads',
              'Track leads & team assignments',
              '/leads',
            ),
            (
              CupertinoIcons.calendar,
              const Color(0xFF34C759),
              'Attendance Management',
              'Approve requests & shifts',
              '/attendance/admin',
            ),
            (
              CupertinoIcons.cart_fill,
              const Color(0xFFFF2D55),
              'Lunch Management',
              'Staff meals & daily counts',
              '/meals/admin',
            ),
            (
              CupertinoIcons.shield_fill,
              const Color(0xFF5856D6),
              'Staff Access',
              'Role permissions & access scope',
              '/staff-access',
            ),
            (
              CupertinoIcons.gear_alt_fill,
              const Color(0xFF00C7BE),
              'Administration',
              'System roles & operations',
              '/administration',
            ),
            (
              CupertinoIcons.settings_solid,
              const Color(0xFF8E8E93),
              'System Settings',
              'App defaults & company profile',
              '/system-settings',
            ),
            (
              CupertinoIcons.doc_text_fill,
              const Color(0xFF32ADE6),
              'Audit Logs',
              'View security & activity logs',
              '/audit-logs',
            ),
          ];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AttendanceMetrics(items: [
                (
                  'Active staff',
                  employees.loadError == null ? '${active.length}' : '—',
                  nec.brand
                ),
                (
                  'Total leads',
                  LeadStore.instance.loadError == null
                      ? '${LeadStore.instance.leads.length}'
                      : '—',
                  nec.brand
                ),
                (
                  'Requests to review',
                  attendance.loadError == null ? '$pending' : '—',
                  CupertinoColors.systemOrange
                ),
                (
                  'Today’s lunches',
                  attendance.loadError == null &&
                          MealStore.instance.loadError == null
                      ? '$lunches'
                      : '—',
                  CupertinoColors.systemGreen
                ),
              ]),
              if (employees.loadError != null ||
                  LeadStore.instance.loadError != null ||
                  attendance.loadError != null ||
                  MealStore.instance.loadError != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        'Some management data could not be loaded. Open the relevant management screen for details.',
                        style:
                            TextStyle(color: nec.textSecondary, fontSize: 12))),
              const SizedBox(height: 20),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    if (index > 0)
                      Divider(
                          height: 1,
                          indent: 68,
                          color: nec.separator.withValues(alpha: 0.3)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: actions[index].$2.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(actions[index].$1,
                            color: actions[index].$2, size: 20),
                      ),
                      title: Text(
                        actions[index].$3,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: nec.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        actions[index].$4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: nec.textTertiary,
                      ),
                      onTap: () => context.pushAppRoute(actions[index].$5),
                    ),
                  ],
                ]),
              ),
            ]),
          );
        },
      );
}

class AdminProfileActivityTab extends StatelessWidget {
  final String employeeId;

  const AdminProfileActivityTab({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation:
            Listenable.merge([AttendanceStore.instance, MealStore.instance]),
        builder: (context, _) {
          if (!DemoSession.instance.isAdmin) return const SizedBox.shrink();
          final nec = Theme.of(context).extension<NecColors>()!;
          final employees = EmployeeStore.instance;
          final events = <(DateTime, String, String)>[
            for (final event in AttendanceStore.instance.state.events)
              if (event.actorId == employeeId &&
                  (event.employeeId.isEmpty ||
                      employees.isStaffEmployee(event.employeeId)))
                (
                  event.at,
                  event.title,
                  employees.byId(event.employeeId)?.name ?? 'Attendance policy'
                ),
            for (final change in MealStore.instance.changesByActor(employeeId))
              (
                change.updatedAt,
                change.takeLunch
                    ? 'Staff lunch enabled'
                    : 'Staff lunch skipped',
                '${employees.byId(change.employeeId)?.name ?? 'Staff'} · ${AttendanceClock.dayLabel(change.day)}'
              ),
          ]..sort((a, b) => b.$1.compareTo(a.$1));
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RECENT ADMINISTRATION ACTIVITY',
                  style: TextStyle(
                      color: nec.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (AttendanceStore.instance.loadError != null ||
                  MealStore.instance.loadError != null)
                AttendanceCard(
                    child: Text(
                        'Some administration activity could not be loaded. Restart the app to try again.',
                        style:
                            TextStyle(color: nec.textSecondary, height: 1.5)))
              else if (events.isEmpty)
                AttendanceCard(
                    child: Text(
                        'No administration activity yet. Your attendance reviews and lunch changes will appear here.',
                        style:
                            TextStyle(color: nec.textSecondary, height: 1.5)))
              else
                Material(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (var index = 0;
                        index < events.take(20).length;
                        index++) ...[
                      if (index > 0)
                        Divider(height: 1, indent: 16, color: nec.separator),
                      ListTile(
                        title: Text(events[index].$2),
                        subtitle: Text(
                            '${events[index].$3}\n${DateFormat('d MMM yyyy · h:mm a').format(AttendanceClock.wallTime(events[index].$1))}'),
                        isThreeLine: true,
                      ),
                    ],
                  ]),
                ),
              const SizedBox(height: 12),
              TextButton.icon(
                  onPressed: () => context.pushAppRoute('/audit-logs'),
                  icon: const Icon(CupertinoIcons.doc_text_search, size: 18),
                  label: const Text('Open Organization Audit Logs')),
            ]),
          );
        },
      );
}
