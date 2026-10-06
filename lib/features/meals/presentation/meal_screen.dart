import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../attendance/data/attendance_clock.dart';
import '../../attendance/data/attendance_store.dart';
import '../../attendance/presentation/widgets/attendance_pickers.dart';
import '../../attendance/presentation/widgets/attendance_ui.dart';
import '../../settings/data/system_settings_store.dart';
import '../../team/data/employee_store.dart';
import '../../team/domain/models/employee.dart';
import '../data/meal_store.dart';
import '../domain/models/lunch_preference.dart';

class MealScreen extends StatefulWidget {
  final bool administrator;

  const MealScreen({super.key, this.administrator = false});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  late String _day;
  final _saving = <String>{};
  final _search = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _day = AttendanceClock.key(AttendanceClock.today
        .add(Duration(days: widget.administrator ? 0 : 1)));
    _search.addListener(_refresh);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _change(Employee employee, bool takeLunch) async {
    if (_saving.contains(employee.id)) {
      return;
    }
    final actor = widget.administrator
        ? AttendanceStore.instance.administratorId
        : EmployeeStore.currentEmployeeId;
    if (actor == null) {
      return;
    }
    setState(() => _saving.add(employee.id));
    try {
      await MealStore.instance.setLunch(
          employeeId: employee.id,
          day: _day,
          takeLunch: takeLunch,
          actorId: actor);
      if (mounted) {
        NecToast.show(context,
            message:
                takeLunch ? 'Office lunch restored' : 'Office lunch skipped');
      }
    } catch (error) {
      if (mounted) {
        attendanceError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving.remove(employee.id));
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await pickAttendanceDate(context, AttendanceClock.date(_day),
        first: widget.administrator
            ? AttendanceClock.date(
                AttendanceStore.instance.policy.trackingStart)
            : AttendanceClock.today);
    if (mounted && date != null) {
      setState(() => _day = AttendanceClock.key(date));
    }
  }

  Color _color(LunchStatus status, NecColors nec) => switch (status) {
        LunchStatus.receiving => CupertinoColors.systemGreen,
        LunchStatus.skipped => CupertinoColors.systemOrange,
        _ => nec.textTertiary,
      };

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([
          MealStore.instance,
          AttendanceStore.instance,
          EmployeeStore.instance,
          SystemSettingsStore.instance
        ]),
        builder: (context, _) {
          final nec = Theme.of(context).extension<NecColors>()!;
          final store = MealStore.instance;
          final actor = AttendanceStore.instance.administratorId;
          final employees = EmployeeStore.instance.employees
              .where((employee) => employee.status == 'Active')
              .toList();
          final error = store.loadError ?? AttendanceStore.instance.loadError;
          final own = EmployeeStore.instance.currentEmployee;
          final history =
              store.historyFor(widget.administrator ? null : own.id, _day);
          final needed = employees
              .where((employee) =>
                  store.statusFor(employee.id, _day) == LunchStatus.receiving)
              .length;
          final skipped = employees
              .where((employee) =>
                  store.statusFor(employee.id, _day) == LunchStatus.skipped)
              .length;
          return Scaffold(
            backgroundColor: nec.bg,
            appBar: attendanceAppBar(context,
                widget.administrator ? 'Lunch Management' : 'My Lunch'),
            body: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.administrator && actor == null)
                          const AttendanceEmpty(
                              title: 'Administrator access required',
                              message:
                                  'An active administrator is required to manage office lunches.')
                        else ...[
                          AttendanceCard(
                              child: Row(children: [
                            Icon(CupertinoIcons.cart,
                                color: nec.brand, size: 30),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Office Lunch',
                                      style: TextStyle(
                                          color: nec.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 5),
                                  Text('Lunch only · included on working days',
                                      style: TextStyle(
                                          color: nec.textSecondary,
                                          fontSize: 13)),
                                ])),
                          ])),
                          const SizedBox(height: 18),
                          AttendancePickerRow(
                              label: 'Lunch Date',
                              value: AttendanceClock.dayLabel(_day),
                              icon: CupertinoIcons.calendar,
                              onTap: _saving.isEmpty ? _pickDate : () {}),
                          Wrap(spacing: 8, children: [
                            for (var offset = 0; offset < 2; offset++)
                              ChoiceChip(
                                label: Text(offset == 0 ? 'Today' : 'Tomorrow'),
                                selected: _day ==
                                    AttendanceClock.key(AttendanceClock.today
                                        .add(Duration(days: offset))),
                                onSelected: _saving.isEmpty
                                    ? (_) => setState(() => _day =
                                        AttendanceClock.key(AttendanceClock
                                            .today
                                            .add(Duration(days: offset))))
                                    : null,
                              ),
                          ]),
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Text(error,
                                style: const TextStyle(
                                    color: CupertinoColors.systemRed)),
                          ],
                          const SizedBox(height: 18),
                          if (widget.administrator) ...[
                            AttendanceMetrics(items: [
                              (
                                'Lunches needed',
                                '$needed',
                                CupertinoColors.systemGreen
                              ),
                              (
                                'Skipping lunch',
                                '$skipped',
                                CupertinoColors.systemOrange
                              ),
                              (
                                'Off / on leave',
                                '${employees.length - needed - skipped}',
                                nec.textTertiary
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Text(
                                'Counts include all active staff. Weekly off days, holidays and swapped off days are excluded unless attendance is recorded. Approved full-day leave is also excluded.',
                                style: TextStyle(
                                    color: nec.textSecondary,
                                    fontSize: 12,
                                    height: 1.5)),
                            const AttendanceHeading('Staff lunches'),
                            CupertinoSearchTextField(
                                controller: _search,
                                placeholder: 'Search staff or employee ID',
                                style: TextStyle(color: nec.textPrimary),
                                backgroundColor: nec.surface),
                            const SizedBox(height: 14),
                            ...employees
                                .where((employee) =>
                                    '${employee.name} ${employee.displayCode}'
                                        .toLowerCase()
                                        .contains(
                                            _search.text.trim().toLowerCase()))
                                .map((employee) =>
                                    _employeeRow(employee, nec, error == null)),
                            if (employees.isEmpty)
                              const AttendanceEmpty(
                                  title: 'No active staff',
                                  message:
                                      'Active employee lunches will appear here.'),
                            const SizedBox(height: 12),
                            Text(
                                'Admin can update today’s or future lunches. Past dates are read-only.',
                                style: TextStyle(
                                    color: nec.textTertiary, fontSize: 12)),
                          ] else ...[
                            _employeeRow(own, nec, error == null),
                            const SizedBox(height: 10),
                            Text(
                                'Turn lunch off if you won’t take it, or turn it back on to restore it. Change upcoming lunches before that day begins (${AttendanceClock.timezone}). Contact admin for today’s changes.',
                                style: TextStyle(
                                    color: nec.textSecondary,
                                    fontSize: 13,
                                    height: 1.5)),
                            const AttendanceHeading('Next 7 days'),
                            AttendanceCard(
                                padding: EdgeInsets.zero,
                                child: Column(children: [
                                  for (var index = 1; index <= 7; index++)
                                    _upcomingRow(index, nec),
                                ])),
                          ],
                          const AttendanceHeading('Changes for this date'),
                          ...history.map((change) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AttendanceCard(
                                  child: Text(
                                      '${widget.administrator ? '${EmployeeStore.instance.byId(change.employeeId)?.name ?? 'Employee'} · ' : ''}${change.takeLunch ? 'Lunch restored' : 'Lunch skipped'}\nChanged by ${EmployeeStore.instance.byId(change.actorId)?.name ?? 'Employee'} · ${AttendanceClock.dayLabel(AttendanceClock.key(AttendanceClock.wallTime(change.updatedAt)))} · ${AttendanceClock.time(change.updatedAt)}',
                                      style: TextStyle(
                                          color: nec.textSecondary,
                                          fontSize: 12,
                                          height: 1.5))))),
                          if (history.isEmpty)
                            Text('No lunch changes recorded for this date.',
                                style: TextStyle(
                                    color: nec.textTertiary, fontSize: 12)),
                        ],
                      ]),
                )),
          );
        },
      );

  Widget _employeeRow(Employee employee, NecColors nec, bool ready) {
    final store = MealStore.instance;
    final status = store.statusFor(employee.id, _day);
    final busy = _saving.contains(employee.id);
    final enabled = ready &&
        !busy &&
        status.available &&
        store.canChange(_day, administrator: widget.administrator);
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AttendanceCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              if (widget.administrator) ...[
                NecAvatar(
                    initials: employee.avatarInitials,
                    photoBase64: employee.photoBase64,
                    size: 36),
                const SizedBox(width: 12),
              ],
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        widget.administrator
                            ? employee.name
                            : 'Take Office Lunch',
                        style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 7),
                    AttendanceBadge(status.label, _color(status, nec)),
                    if (!status.available) ...[
                      const SizedBox(height: 6),
                      Text('No lunch scheduled',
                          style:
                              TextStyle(color: nec.textTertiary, fontSize: 12))
                    ],
                  ])),
              const SizedBox(width: 12),
              if (busy)
                const CupertinoActivityIndicator()
              else
                CupertinoSwitch(
                    value: status == LunchStatus.receiving,
                    onChanged:
                        enabled ? (value) => _change(employee, value) : null),
            ])));
  }

  Widget _upcomingRow(int index, NecColors nec) {
    final day =
        AttendanceClock.key(AttendanceClock.today.add(Duration(days: index)));
    final status =
        MealStore.instance.statusFor(EmployeeStore.currentEmployeeId, day);
    return Column(children: [
      if (index > 1) Divider(height: 1, color: nec.separator, indent: 16),
      ListTile(
          title: Text(AttendanceClock.dayLabel(day),
              style: TextStyle(color: nec.textPrimary, fontSize: 14)),
          trailing: AttendanceBadge(status.label, _color(status, nec)),
          onTap: _saving.isEmpty ? () => setState(() => _day = day) : null),
    ]);
  }
}
