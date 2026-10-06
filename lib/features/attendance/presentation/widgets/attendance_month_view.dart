import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/attendance_clock.dart';
import '../../data/attendance_store.dart';
import '../../domain/models/attendance_models.dart';
import 'attendance_day_detail.dart';
import 'attendance_ui.dart';
import 'attendance_pickers.dart';

class AttendanceMonthView extends StatefulWidget {
  final String employeeId;
  final String? actorId;
  final DateTime? initialMonth;

  const AttendanceMonthView(
      {super.key, required this.employeeId, this.actorId, this.initialMonth});

  @override
  State<AttendanceMonthView> createState() => _AttendanceMonthViewState();
}

class _AttendanceMonthViewState extends State<AttendanceMonthView> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final candidate = widget.initialMonth ?? AttendanceClock.today;
    final today =
        candidate.year < 2000 || candidate.year > AttendanceClock.today.year + 3
            ? AttendanceClock.today
            : candidate;
    _month = DateTime.utc(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final days = AttendanceStore.instance.monthFor(widget.employeeId, _month);
    final present = days
        .where((day) => [
              AttendanceStatus.present,
              AttendanceStatus.late,
              AttendanceStatus.working,
              AttendanceStatus.onBreak,
              AttendanceStatus.halfDay,
              AttendanceStatus.shortDay
            ].contains(day.status))
        .length;
    final absent = days
        .where((day) => day.status == AttendanceStatus.absent)
        .fold(0.0, (sum, day) => sum + 1 - day.leaveDays);
    final leave = days.fold(0.0, (sum, day) => sum + day.leaveDays);
    final first = _month.weekday % 7;
    final weeks = ((first + days.length) / 7).ceil();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
            tooltip: 'Previous month',
            onPressed: _month.year <= 2000 && _month.month == 1
                ? null
                : () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month - 1)),
            icon:
                Icon(CupertinoIcons.chevron_left, color: nec.brand, size: 20)),
        Expanded(
            child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  final date = await pickAttendanceDate(context, _month);
                  if (mounted && date != null) {
                    setState(
                        () => _month = DateTime.utc(date.year, date.month));
                  }
                },
                child: Text(DateFormat('MMMM yyyy').format(_month),
                    style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)))),
        IconButton(
            tooltip: 'Next month',
            onPressed: _month.year >= AttendanceClock.today.year + 3 &&
                    _month.month == 12
                ? null
                : () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month + 1)),
            icon:
                Icon(CupertinoIcons.chevron_right, color: nec.brand, size: 20))
      ]),
      const SizedBox(height: 8),
      AttendanceCard(child: LayoutBuilder(builder: (context, constraints) {
        final size = ((constraints.maxWidth - 32 - weeks * 7) / weeks)
            .clamp(20, 43)
            .toDouble();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your month, one day at a time',
              style: TextStyle(color: nec.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 32,
                child: Column(
                    children: List.generate(
                        7,
                        (row) => SizedBox(
                            height: size + 7,
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                    [
                                      'Sun',
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat'
                                    ][row],
                                    style: TextStyle(
                                        color: nec.textTertiary,
                                        fontSize: 10))))))),
            for (var week = 0; week < weeks; week++)
              Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: Column(
                      children: List.generate(7, (row) {
                    final index = week * 7 + row - first;
                    if (index < 0 || index >= days.length) {
                      return SizedBox(width: size, height: size + 7);
                    }
                    final day = days[index];
                    final colored = [
                      AttendanceStatus.present,
                      AttendanceStatus.late,
                      AttendanceStatus.working,
                      AttendanceStatus.onBreak,
                      AttendanceStatus.halfDay,
                      AttendanceStatus.shortDay,
                      AttendanceStatus.absent,
                      AttendanceStatus.leave,
                      AttendanceStatus.swappedOff
                    ].contains(day.status);
                    final color = attendanceColor(day.status);
                    final opacity = day.status == AttendanceStatus.present
                        ? (.35 + (day.workedMinutes / 480).clamp(0, 1) * .65)
                        : .9;
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Tooltip(
                            message:
                                '${AttendanceClock.dayLabel(day.day)} · ${day.status.label}',
                            child: Semantics(
                                button: true,
                                label:
                                    '${AttendanceClock.dayLabel(day.day)}, ${day.status.label}',
                                child: Material(
                                    color: colored
                                        ? color.withValues(alpha: opacity)
                                        : nec.separator.withValues(alpha: .22),
                                    borderRadius: BorderRadius.circular(7),
                                    child: InkWell(
                                        borderRadius: BorderRadius.circular(7),
                                        onTap: () => showAttendanceSheet(
                                            context,
                                            AttendanceDayDetail(
                                                employeeId: widget.employeeId,
                                                day: day.day,
                                                actorId: widget.actorId)),
                                        child: Container(
                                            width: size,
                                            height: size,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                                border:
                                                    day.day == AttendanceClock.key(AttendanceClock.today)
                                                        ? Border.all(
                                                            color: nec.brand,
                                                            width: 2)
                                                        : null),
                                            child: Text('${index + 1}',
                                                style: TextStyle(color: colored ? Colors.white : nec.textTertiary, fontSize: 11, fontWeight: FontWeight.w600))))))));
                  }))),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 9, children: [
            for (final status in [
              AttendanceStatus.present,
              AttendanceStatus.late,
              AttendanceStatus.halfDay,
              AttendanceStatus.shortDay,
              AttendanceStatus.absent,
              AttendanceStatus.leave,
              AttendanceStatus.swappedOff,
              AttendanceStatus.offDay
            ])
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: attendanceColor(status),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text(status.label,
                    style: TextStyle(color: nec.textSecondary, fontSize: 10))
              ]),
          ]),
          const SizedBox(height: 12),
          Text('Tap a day to see times, breaks, requests, and history.',
              style: TextStyle(color: nec.textTertiary, fontSize: 11)),
        ]);
      })),
      const SizedBox(height: 16),
      AttendanceMetrics(items: [
        (
          'Extra work',
          AttendanceClock.duration(
              days.fold(0, (sum, day) => sum + day.overtimeMinutes)),
          nec.brand
        ),
        (
          'Off days worked',
          '${days.where((day) => day.record?.checkIn != null && day.record?.wasWorkingDay == false && !AttendanceStore.instance.swappedWork(widget.employeeId, day.day)).length}',
          const Color(0xFF30B0C7)
        ),
        ('Days attended', '$present', AppColors.success),
        (
          'Late arrivals',
          '${days.where((day) => day.lateMinutes > 0).length}',
          AppColors.warning
        ),
        (
          'Absent days',
          '${absent % 1 == 0 ? absent.toInt() : absent}',
          AppColors.error
        ),
        (
          'Leave days',
          '${leave % 1 == 0 ? leave.toInt() : leave}',
          const Color(0xFF5856D6)
        ),
        (
          'Worked hours',
          AttendanceClock.duration(
              days.fold(0, (sum, day) => sum + day.workedMinutes)),
          nec.brand
        ),
        (
          'Approved overtime',
          AttendanceClock.duration(
              days.fold(0, (sum, day) => sum + day.approvedOvertimeMinutes)),
          const Color(0xFF30B0C7)
        ),
      ]),
      const AttendanceHeading('Daily history'),
      for (final day in days.reversed
          .where((day) => day.record != null || day.leaveDays > 0))
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                    title: Text(AttendanceClock.dayLabel(day.day),
                        style: TextStyle(color: nec.textPrimary, fontSize: 14)),
                    subtitle: Text(
                        '${AttendanceClock.time(day.record?.checkIn, day.record?.offsetMinutes)} – ${AttendanceClock.time(day.record?.checkOut, day.record?.offsetMinutes)} · ${AttendanceClock.duration(day.workedMinutes)}',
                        style:
                            TextStyle(color: nec.textTertiary, fontSize: 12)),
                    trailing: AttendanceBadge(
                        day.status.label, attendanceColor(day.status)),
                    onTap: () => showAttendanceSheet(
                        context,
                        AttendanceDayDetail(
                            employeeId: widget.employeeId,
                            day: day.day,
                            actorId: widget.actorId))))),
      if (!days.any((day) => day.record != null || day.leaveDays > 0))
        const AttendanceEmpty(
            title: 'No records this month',
            message:
                'Check-ins and approved leave will appear here. Dates before tracking began are never marked absent.'),
    ]);
  }
}
