import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../team/data/employee_store.dart';
import '../../data/attendance_clock.dart';
import '../../data/attendance_store.dart';
import 'attendance_ui.dart';

class AttendanceTodayCard extends StatefulWidget {
  final String employeeId;

  const AttendanceTodayCard({super.key, required this.employeeId});

  @override
  State<AttendanceTodayCard> createState() => _AttendanceTodayCardState();
}

class _AttendanceTodayCardState extends State<AttendanceTodayCard> {
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _act(String action) async {
    if (_busy) {
      return;
    }
    final store = AttendanceStore.instance;
    if (action == 'out') {
      final confirm = await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
                  title: const Text('Finish your workday?'),
                  content: const Text(
                      'Your check-out time and worked hours will be recorded. You can request a correction if needed.'),
                  actions: [
                    CupertinoDialogAction(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Keep Working')),
                    CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Check Out'))
                  ]));
      if (!mounted || confirm != true) {
        return;
      }
    }
    setState(() => _busy = true);
    try {
      switch (action) {
        case 'in':
          await store.checkIn(widget.employeeId);
        case 'out':
          await store.checkOut(widget.employeeId);
        case 'break':
          await store.toggleBreak(widget.employeeId);
      }
      if (mounted) {
        NecToast.show(context,
            message: action == 'in'
                ? 'Check-in recorded'
                : action == 'out'
                    ? 'Check-out recorded'
                    : 'Break updated');
      }
    } catch (error) {
      if (mounted) {
        attendanceError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final store = AttendanceStore.instance;
    final now = AttendanceClock.now;
    final today = store.checkInDay;
    final active = store.activeRecord(widget.employeeId);
    final record = active ?? store.recordFor(widget.employeeId, today);
    final facts =
        store.dayFor(widget.employeeId, record?.day ?? today, now: now);
    final seconds = record?.workedSeconds(now) ?? 0;
    final elapsed =
        '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final target =
        record == null ? store.policy.requiredMinutes : facts.requiredMinutes;
    final employee = EmployeeStore.instance.byId(widget.employeeId);
    final canCheckIn = record == null &&
        employee?.status == 'Active' &&
        facts.leaveDays < 1 &&
        (store.policy.allowOffDayWork ||
            store.isWorkingDay(widget.employeeId, today));
    return Column(children: [
      Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [nec.brand, const Color(0xFF1858C4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(AttendanceClock.dayLabel(today),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .17),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                      record?.checkOut != null
                          ? 'Checked out'
                          : facts.status.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)))
            ]),
            const SizedBox(height: 22),
            const Text('WORKED TIME',
                style: TextStyle(
                    color: Colors.white70, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 7),
            Text(elapsed,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 14),
            ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                    value: target <= 0
                        ? 1
                        : (facts.workedMinutes / target).clamp(0, 1).toDouble(),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: .2),
                    color: Colors.white)),
            const SizedBox(height: 10),
            Text(
                target > 0
                    ? '${AttendanceClock.duration(target)} target · ${AttendanceClock.duration((record?.breakSeconds(now) ?? 0) ~/ 60)} on break'
                    : 'Off-day work · ${AttendanceClock.duration(facts.overtimeMinutes)} extra time',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: _stamp(
                      'Check-in',
                      AttendanceClock.time(
                          record?.checkIn, record?.offsetMinutes))),
              Expanded(
                  child: _stamp(
                      'Check-out',
                      AttendanceClock.time(
                          record?.checkOut, record?.offsetMinutes)))
            ]),
            if (record != null && record.day != today) ...[
              const SizedBox(height: 12),
              Text('Open session from ${AttendanceClock.dayLabel(record.day)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12))
            ],
          ])),
      const SizedBox(height: 14),
      if (active != null)
        Row(children: [
          Expanded(
              child: NecButton(
                  label: active.onBreak ? 'Resume Work' : 'Start Break',
                  variant: NecButtonVariant.tertiary,
                  loading: _busy,
                  onPressed: () => _act('break'))),
          const SizedBox(width: 12),
          Expanded(
              child: NecButton(
                  label: 'Check Out',
                  loading: _busy,
                  onPressed: () => _act('out')))
        ])
      else
        NecButton(
            label: record?.checkOut != null
                ? 'Workday Completed'
                : facts.leaveDays == 1
                    ? 'On Approved Leave'
                    : record != null
                        ? 'Marked Absent'
                        : 'Check In',
            fullWidth: true,
            loading: _busy,
            onPressed: canCheckIn ? () => _act('in') : null,
            icon: const Icon(CupertinoIcons.arrow_right_circle,
                size: 20, color: Colors.white)),
      const SizedBox(height: 10),
      Text(
          '${AttendanceClock.minutesTime(store.policy.startMinutes)} – ${AttendanceClock.minutesTime(store.policy.endMinutes)} · ${AttendanceClock.timezone}',
          textAlign: TextAlign.center,
          style: TextStyle(color: nec.textTertiary, fontSize: 12)),
    ]);
  }

  Widget _stamp(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600))
      ]);
}
