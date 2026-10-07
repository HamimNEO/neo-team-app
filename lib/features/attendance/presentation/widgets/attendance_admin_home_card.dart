import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/management_summary_card.dart';
import '../../../team/data/employee_store.dart';
import '../../data/attendance_clock.dart';
import '../../data/attendance_store.dart';
import '../../domain/models/attendance_models.dart';

class AttendanceAdminHomeCard extends StatelessWidget {
  const AttendanceAdminHomeCard({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge(
            [AttendanceStore.instance, EmployeeStore.instance]),
        builder: (context, _) {
          if (!DemoSession.instance.isAdmin) return const SizedBox.shrink();
          final nec = Theme.of(context).extension<NecColors>()!;
          final employees = EmployeeStore.instance;
          final store = AttendanceStore.instance;
          final active = employees.staffEmployees
              .where((employee) => employee.status == 'Active')
              .toList();
          final day = AttendanceClock.key(AttendanceClock.today);
          final checkedIn = active
              .where((employee) =>
                  store.recordFor(employee.id, day)?.checkIn != null)
              .length;
          final pending = store.allRequests
              .where((request) =>
                  request.status == AttendanceRequestStatus.pending &&
                  employees.isStaffEmployee(request.employeeId))
              .length;
          final available =
              store.loadError == null && employees.loadError == null;
          final progress = active.isEmpty ? 0.0 : checkedIn / active.length;
          return ManagementSummaryCard(
            title: 'Attendance Management',
            subtitle: 'Workforce overview · Today',
            icon: CupertinoIcons.person_2,
            accent: nec.brand,
            metrics: [
              (
                'Staff checked in',
                available ? '$checkedIn / ${active.length}' : '—',
                nec.textPrimary
              ),
              (
                'Requests to review',
                available ? '$pending' : '—',
                pending > 0 ? CupertinoColors.systemOrange : nec.textPrimary
              ),
            ],
            progress: available ? progress : 0,
            progressLabel: !available
                ? 'Attendance data unavailable'
                : active.isEmpty
                    ? 'No active staff accounts'
                    : '${(progress * 100).round()}% of active staff checked in today',
            onTap: () => context.pushAppRoute('/attendance/admin'),
          );
        },
      );
}
