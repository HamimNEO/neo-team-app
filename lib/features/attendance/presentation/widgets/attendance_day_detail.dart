import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../team/data/employee_store.dart';
import '../../data/attendance_clock.dart';
import '../../data/attendance_store.dart';
import '../../domain/models/attendance_models.dart';
import 'attendance_ui.dart';
import 'attendance_edit_form.dart';
import 'attendance_request_form.dart';
import 'attendance_requests.dart';

class AttendanceDayDetail extends StatelessWidget {
  final String employeeId;
  final String day;
  final String? actorId;

  const AttendanceDayDetail(
      {super.key, required this.employeeId, required this.day, this.actorId});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: AttendanceStore.instance,
      builder: (context, _) {
        final nec = Theme.of(context).extension<NecColors>()!;
        final store = AttendanceStore.instance;
        final facts = store.dayFor(employeeId, day);
        final record = facts.record;
        final checkOut = record?.checkOut;
        final requests = store
            .requestsFor(employeeId)
            .where((request) =>
                request.day == day ||
                request.endDay == day ||
                request.leaveUnits.containsKey(day))
            .toList();
        final events = store.state.events
            .where(
                (event) => event.employeeId == employeeId && event.day == day)
            .toList()
            .reversed;
        return AttendanceSheetBody(
            title: AttendanceClock.dayLabel(day),
            children: [
              Row(children: [
                Expanded(
                    child: Text(
                        EmployeeStore.instance.byId(employeeId)?.name ??
                            'Employee',
                        style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w600))),
                AttendanceBadge(
                    facts.status.label, attendanceColor(facts.status))
              ]),
              const SizedBox(height: 20),
              AttendanceValues(rows: [
                (
                  'Check-in',
                  AttendanceClock.time(record?.checkIn, record?.offsetMinutes)
                ),
                (
                  'Check-out',
                  '${AttendanceClock.time(checkOut, record?.offsetMinutes)}${checkOut != null && AttendanceClock.key(AttendanceClock.wallTime(checkOut, record?.offsetMinutes)) != day ? ' (next day)' : ''}'
                ),
                ('Worked Time', AttendanceClock.duration(facts.workedMinutes)),
                (
                  'Break Time',
                  AttendanceClock.duration(
                      (record?.breakSeconds(AttendanceClock.now) ?? 0) ~/ 60)
                ),
                ('Late Arrival', AttendanceClock.duration(facts.lateMinutes)),
                ('Extra Work', AttendanceClock.duration(facts.overtimeMinutes)),
                (
                  'Approved Overtime',
                  AttendanceClock.duration(facts.approvedOvertimeMinutes)
                ),
                if (facts.leaveDays > 0) ('Leave', '${facts.leaveDays} day'),
                if (record?.corrected == true)
                  ('Record', 'Corrected by administrator'),
                if (facts.note.isNotEmpty) ('Note', facts.note),
              ]),
              if (record != null && record.breaks.isNotEmpty) ...[
                const AttendanceHeading('Breaks'),
                AttendanceValues(
                    rows: record.breaks
                        .asMap()
                        .entries
                        .map((entry) => (
                              'Break ${entry.key + 1}',
                              '${AttendanceClock.time(entry.value.start, record.offsetMinutes)} – ${AttendanceClock.time(entry.value.end, record.offsetMinutes)}'
                            ))
                        .toList()),
              ],
              if (requests.isNotEmpty) ...[
                const AttendanceHeading('Requests'),
                ...requests.map((request) =>
                    AttendanceRequestTile(request: request, actorId: actorId))
              ],
              const AttendanceHeading('Record history'),
              if (events.isEmpty)
                Text('No attendance changes recorded.',
                    style: TextStyle(color: nec.textTertiary, fontSize: 13)),
              for (final event in events)
                Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AttendanceCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(event.title,
                              style: TextStyle(
                                  color: nec.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 5),
                          Text(
                              '${EmployeeStore.instance.byId(event.actorId)?.name ?? 'Administrator'} · ${AttendanceClock.dayLabel(AttendanceClock.key(AttendanceClock.wallTime(event.at, record?.offsetMinutes)))} · ${AttendanceClock.time(event.at, record?.offsetMinutes)}',
                              style: TextStyle(
                                  color: nec.textTertiary, fontSize: 12)),
                          if (event.before?.containsKey('checkIn') == true &&
                              event.after?.containsKey('checkIn') == true &&
                              (event.title.contains('Attendance') ||
                                  event.title.contains('fix approved'))) ...[
                            const SizedBox(height: 8),
                            Text(
                                'In: ${AttendanceClock.time(AttendanceRecord.fromJson(event.before!).checkIn, record?.offsetMinutes)} → ${AttendanceClock.time(AttendanceRecord.fromJson(event.after!).checkIn, record?.offsetMinutes)}\nOut: ${AttendanceClock.time(AttendanceRecord.fromJson(event.before!).checkOut, record?.offsetMinutes)} → ${AttendanceClock.time(AttendanceRecord.fromJson(event.after!).checkOut, record?.offsetMinutes)}',
                                style: TextStyle(
                                    color: nec.textSecondary, fontSize: 12)),
                          ],
                          if ((event.after?['note'] as String? ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(event.after!['note'] as String,
                                style: TextStyle(
                                    color: nec.textSecondary, fontSize: 12)),
                          ],
                        ]))),
              const SizedBox(height: 20),
              if (actorId != null &&
                  day.compareTo(AttendanceClock.key(AttendanceClock.today)) <=
                      0)
                NecButton(
                    label: 'Manage This Day',
                    fullWidth: true,
                    onPressed: () => showAttendanceSheet(
                        context,
                        AttendanceEditForm(
                            employeeId: employeeId,
                            day: day,
                            actorId: actorId!)))
              else if (employeeId == EmployeeStore.currentEmployeeId &&
                  day.compareTo(AttendanceClock.key(AttendanceClock.today)) <=
                      0)
                NecButton(
                    label: 'Request Attendance Fix',
                    fullWidth: true,
                    icon: const Icon(CupertinoIcons.square_pencil,
                        size: 18, color: Colors.white),
                    onPressed: () => showAttendanceSheet(
                        context,
                        AttendanceRequestForm(
                            employeeId: employeeId,
                            kind: AttendanceRequestKind.correction,
                            day: day))),
            ]);
      });
}
