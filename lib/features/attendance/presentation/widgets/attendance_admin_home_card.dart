import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/services/demo_session.dart';
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final employees = EmployeeStore.instance;
          final store = AttendanceStore.instance;
          final active = employees.staffEmployees
              .where((employee) => employee.status == 'Active')
              .toList();
          final day = AttendanceClock.key(AttendanceClock.today);
          final checkedInFromRecords = active
              .where((employee) =>
                  store.recordFor(employee.id, day)?.checkIn != null)
              .length;
          final checkedIn = store.remoteCheckedInCount != null &&
                  store.remoteCheckedInCount! > checkedInFromRecords
              ? store.remoteCheckedInCount!
              : checkedInFromRecords;
          final pending = store.remoteRequestsCount ??
              store.allRequests
                  .where((request) =>
                      request.status == AttendanceRequestStatus.pending &&
                      employees.isStaffEmployee(request.employeeId))
                  .length;
          final available =
              store.loadError == null && employees.loadError == null;
          final progress = active.isEmpty ? 0.0 : checkedIn / active.length;
          final percentInt = (progress * 100).round();

          const accent = Color(0xFF007AFF);
          final metric1Bg =
              isDark ? const Color(0xFF0F2B48) : const Color(0xFFEBF5FF);
          final metric2Bg = isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF3F4F6);
          final metric2Fg =
              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);

          return ManagementSummaryCard(
            title: 'Attendance Management',
            subtitle: 'Workforce overview · Today',
            icon: CupertinoIcons.person_2_fill,
            accent: accent,
            metrics: [
              ManagementMetricItem(
                icon: CupertinoIcons.person_2,
                iconBg: metric1Bg,
                iconColor: accent,
                value: available ? '$checkedIn / ${active.length}' : '—',
                label: 'Staff checked in',
              ),
              ManagementMetricItem(
                icon: CupertinoIcons.doc_text_fill,
                iconBg: metric2Bg,
                iconColor: metric2Fg,
                value: available ? '$pending' : '—',
                label: 'Requests to review',
              ),
            ],
            progress: available ? progress : 0,
            percentageText: available ? '$percentInt%' : '0%',
            progressLabel: !available
                ? 'Attendance data unavailable'
                : active.isEmpty
                    ? 'No active staff accounts'
                    : '$percentInt% of active staff checked in today',
            onTap: () => context.pushAppRoute('/attendance/admin'),
          );
        },
      );
}
