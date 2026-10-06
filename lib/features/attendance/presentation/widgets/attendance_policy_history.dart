import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../team/data/employee_store.dart';
import '../../data/attendance_clock.dart';
import '../../data/attendance_store.dart';
import '../../domain/models/attendance_models.dart';
import 'attendance_ui.dart';

class AttendancePolicyHistory extends StatelessWidget {
  const AttendancePolicyHistory({super.key});

  List<(String, String)> _values(AttendancePolicy policy) => [
        (
          'Office Hours',
          '${AttendanceClock.minutesTime(policy.startMinutes)} – ${AttendanceClock.minutesTime(policy.endMinutes)}'
        ),
        ('Required Work', AttendanceClock.duration(policy.requiredMinutes)),
        ('Late Grace', '${policy.graceMinutes} minutes'),
        ('Paid Break Allowance', '${policy.paidBreakMinutes} minutes'),
        (
          'Weekly Off',
          policy.offWeekdays.isEmpty
              ? 'None'
              : policy.offWeekdays
                  .map((day) => [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday'
                      ][day - 1])
                  .join(', ')
        ),
        ('Fix Window', '${policy.correctionWindowDays} days'),
        ('Off-day Work', policy.allowOffDayWork ? 'Allowed' : 'Disabled'),
        (
          'Backdated Leave',
          policy.allowBackdatedLeave ? 'Allowed' : 'Disabled'
        ),
        (
          'Overtime Approval',
          policy.overtimeApprovalRequired ? 'Required' : 'Automatic'
        ),
        ('Tracking Begins', AttendanceClock.dayLabel(policy.trackingStart)),
        (
          'Leave Types',
          policy.leaveTypes
              .map((type) =>
                  '${type.name}: ${type.annualDays ?? 'Unlimited'} days, ${type.paid ? 'paid' : 'unpaid'}, ${type.enabled ? 'enabled' : 'disabled'}')
              .join('\n')
        ),
        (
          'Holidays',
          policy.holidays.isEmpty
              ? 'None'
              : policy.holidays
                  .map((holiday) =>
                      '${holiday.name} · ${AttendanceClock.dayLabel(holiday.day)}')
                  .join('\n')
        ),
      ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: AttendanceStore.instance,
      builder: (context, _) {
        final nec = Theme.of(context).extension<NecColors>()!;
        final changes = AttendanceStore.instance.state.events
            .where((event) =>
                event.employeeId.isEmpty &&
                event.before?.containsKey('startMinutes') == true &&
                event.after?.containsKey('startMinutes') == true)
            .toList()
            .reversed
            .toList();
        if (changes.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: AttendanceCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                    title: Text('Settings History',
                        style: TextStyle(color: nec.textPrimary, fontSize: 15)),
                    subtitle: Text('${changes.length} recorded changes',
                        style:
                            TextStyle(color: nec.textTertiary, fontSize: 12)),
                    children: changes.map((event) {
                      final actor =
                          EmployeeStore.instance.byId(event.actorId)?.name ??
                              'Administrator';
                      final timestamp =
                          '${AttendanceClock.dayLabel(AttendanceClock.key(AttendanceClock.wallTime(event.at)))} · ${AttendanceClock.time(event.at)}';
                      return ListTile(
                          title: Text(actor,
                              style: TextStyle(
                                  color: nec.textPrimary, fontSize: 14)),
                          subtitle: Text(timestamp,
                              style: TextStyle(
                                  color: nec.textTertiary, fontSize: 12)),
                          onTap: () => showAttendanceSheet(
                              context,
                              AttendanceSheetBody(
                                  title: 'Settings Change',
                                  children: [
                                    AttendanceValues(rows: [
                                      ('Changed By', actor),
                                      ('Timestamp', timestamp)
                                    ]),
                                    const AttendanceHeading(
                                        'Previous settings'),
                                    AttendanceValues(
                                        rows: _values(AttendancePolicy.fromJson(
                                            event.before!))),
                                    const AttendanceHeading('Updated settings'),
                                    AttendanceValues(
                                        rows: _values(AttendancePolicy.fromJson(
                                            event.after!))),
                                  ])));
                    }).toList())));
      });
}
