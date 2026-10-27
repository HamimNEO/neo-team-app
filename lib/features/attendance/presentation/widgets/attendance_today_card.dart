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

    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: nec.separator.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: nec.textTertiary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF43F5E), Color(0xFFFB923C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF43F5E)
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.square_arrow_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Finish Workday?',
                                style: TextStyle(
                                  color: nec.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Record check-out and complete session',
                                style: TextStyle(
                                  color: nec.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx, false),
                          icon: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: nec.textTertiary.withValues(alpha: 0.5),
                            size: 24,
                          ),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (elapsed.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: nec.separator.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                CupertinoIcons.stopwatch,
                                color: Color(0xFFE11D48),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TIME WORKED TODAY',
                                    style: TextStyle(
                                      color: nec.textTertiary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    elapsed,
                                    style: TextStyle(
                                      color: nec.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: Color(0xFFE11D48),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Clocking Out',
                                    style: TextStyle(
                                      color: Color(0xFFE11D48),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Workday Summary',
                      style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _summaryController,
                      minLines: 1,
                      maxLines: 2,
                      style: TextStyle(color: nec.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Summary (optional)',
                        hintStyle: TextStyle(
                          color: nec.textTertiary.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: nec.separator.withValues(alpha: 0.6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: nec.separator.withValues(alpha: 0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE11D48), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Work Notes / Handover',
                      style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _workNotesController,
                      minLines: 1,
                      maxLines: 2,
                      style: TextStyle(color: nec.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Notes (optional)',
                        hintStyle: TextStyle(
                          color: nec.textTertiary.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: nec.separator.withValues(alpha: 0.6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: nec.separator.withValues(alpha: 0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE11D48), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetCtx, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: nec.textPrimary,
                              side: BorderSide(
                                  color: nec.separator.withValues(alpha: 0.8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Keep Working',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(sheetCtx, true),
                            icon: const Icon(CupertinoIcons.square_arrow_right,
                                size: 17),
                            label: const Text(
                              'Check Out',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE11D48),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          _summaryController.clear();
          _workNotesController.clear();
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
