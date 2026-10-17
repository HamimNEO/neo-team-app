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
  String? _activeAction;
  final _summaryController = TextEditingController();
  final _workNotesController = TextEditingController();

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
    _summaryController.dispose();
    _workNotesController.dispose();
    super.dispose();
  }

  Future<bool> _confirmCheckOut(BuildContext context, String elapsed) async {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: nec.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF382318) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.clock_fill,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Finish Workday?',
                style: TextStyle(
                  color: nec.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your check-out time will be recorded. Are you sure you want to end your workday session?',
              style: TextStyle(
                color: nec.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _summaryController,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Workday summary (optional)')),
            TextField(
                controller: _workNotesController,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Work notes (optional)')),
            if (elapsed.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      'Time Worked Today:',
                      style: TextStyle(color: nec.textTertiary, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      elapsed,
                      style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Keep Working',
              style: TextStyle(
                color: nec.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Check Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _act(String action, {String elapsed = ''}) async {
    if (_activeAction != null) {
      return;
    }
    if (action == 'out') {
      final confirm = await _confirmCheckOut(context, elapsed);
      if (!mounted || !confirm) {
        return;
      }
    }
    setState(() => _activeAction = action);
    try {
      final store = AttendanceStore.instance;
      switch (action) {
        case 'in':
          await store.checkIn(widget.employeeId);
        case 'out':
          await store.checkOut(widget.employeeId,
              summary: _summaryController.text.trim(),
              workNotes: _workNotesController.text.trim());
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
        setState(() => _activeAction = null);
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
                  loading: _activeAction == 'break',
                  onPressed:
                      _activeAction != null ? null : () => _act('break'))),
          const SizedBox(width: 12),
          Expanded(
              child: NecButton(
                  label: 'Check Out',
                  loading: _activeAction == 'out',
                  onPressed: _activeAction != null
                      ? null
                      : () => _act('out', elapsed: elapsed)))
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
            loading: _activeAction == 'in',
            onPressed:
                canCheckIn && _activeAction == null ? () => _act('in') : null,
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
