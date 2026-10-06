import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/attendance_clock.dart';
import '../data/attendance_store.dart';
import '../domain/models/attendance_models.dart';
import 'widgets/attendance_pickers.dart';
import 'widgets/attendance_ui.dart';
import 'widgets/attendance_policy_history.dart';

class AttendanceSettingsScreen extends StatefulWidget {
  const AttendanceSettingsScreen({super.key});

  @override
  State<AttendanceSettingsScreen> createState() =>
      _AttendanceSettingsScreenState();
}

class _AttendanceSettingsScreenState extends State<AttendanceSettingsScreen> {
  final _form = GlobalKey<FormState>();
  late AttendancePolicy _policy;
  late final TextEditingController _required;
  late final TextEditingController _grace;
  late final TextEditingController _paidBreak;
  late final TextEditingController _window;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _policy = AttendanceStore.instance.policy;
    _required = TextEditingController(text: '${_policy.requiredMinutes}');
    _grace = TextEditingController(text: '${_policy.graceMinutes}');
    _paidBreak = TextEditingController(text: '${_policy.paidBreakMinutes}');
    _window = TextEditingController(text: '${_policy.correctionWindowDays}');
  }

  @override
  void dispose() {
    for (final controller in [_required, _grace, _paidBreak, _window]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final actor = AttendanceStore.instance.administratorId;
    if (actor == null) {
      attendanceError(context,
          const FormatException('An active administrator is required.'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      _policy = _policy.copyWith(
          requiredMinutes: int.parse(_required.text),
          graceMinutes: int.parse(_grace.text),
          paidBreakMinutes: int.parse(_paidBreak.text),
          correctionWindowDays: int.parse(_window.text));
      await AttendanceStore.instance.updatePolicy(_policy, actorId: actor);
      if (mounted) {
        NecToast.show(context, message: 'Attendance settings saved');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message
            : 'Unable to save attendance settings.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _number(
          String label, TextEditingController controller) =>
      AttendanceField(
          label: label,
          controller: controller,
          keyboardType: TextInputType.number,
          validator: (value) => int.tryParse(value ?? '') == null
              ? 'Enter a whole number.'
              : null);

  Widget _toggle(
      String title, String subtitle, bool value, ValueChanged<bool> changed) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(color: nec.textPrimary, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: nec.textTertiary, fontSize: 12, height: 1.4))
              ])),
          const SizedBox(width: 12),
          CupertinoSwitch(value: value, onChanged: changed)
        ]));
  }

  Future<void> _leaveType([LeaveType? original]) async {
    final type = await showAttendanceSheet<LeaveType>(
        context, _LeaveTypeEditor(original: original));
    if (!mounted || type == null) {
      return;
    }
    setState(() => _policy = _policy.copyWith(leaveTypes: [
          ..._policy.leaveTypes.where((item) => item.id != type.id),
          type
        ]));
  }

  Future<void> _holiday([AttendanceHoliday? original]) async {
    final holiday = await showAttendanceSheet<AttendanceHoliday>(
        context, _HolidayEditor(original: original));
    if (!mounted || holiday == null) {
      return;
    }
    if (_policy.holidays
        .any((item) => item.day == holiday.day && item.day != original?.day)) {
      attendanceError(context,
          const FormatException('A holiday already exists on this date.'));
      return;
    }
    setState(() => _policy = _policy.copyWith(
            holidays: [
          ..._policy.holidays.where((item) => item.day != original?.day),
          holiday
        ]..sort((a, b) => a.day.compareTo(b.day))));
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return PopScope(
        canPop: !_saving,
        child: Scaffold(
            backgroundColor: nec.bg,
            appBar: attendanceAppBar(context, 'Attendance Settings'),
            body: SafeArea(
                bottom: false,
                child: AbsorbPointer(
                  absorbing: _saving,
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      child: Form(
                          key: _form,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AttendanceHeading('Office schedule'),
                                AttendanceCard(
                                    child: Column(children: [
                                  AttendancePickerRow(
                                      label: 'Office Opens',
                                      value: AttendanceClock.minutesTime(
                                          _policy.startMinutes),
                                      icon: CupertinoIcons.clock,
                                      onTap: () async {
                                        final time = await pickAttendanceTime(
                                            context, _policy.startMinutes);
                                        if (mounted && time != null) {
                                          setState(() => _policy = _policy
                                              .copyWith(startMinutes: time));
                                        }
                                      }),
                                  AttendancePickerRow(
                                      label: 'Office Closes',
                                      value: AttendanceClock.minutesTime(
                                          _policy.endMinutes),
                                      icon: CupertinoIcons.clock,
                                      onTap: () async {
                                        final time = await pickAttendanceTime(
                                            context, _policy.endMinutes);
                                        if (mounted && time != null) {
                                          setState(() => _policy = _policy
                                              .copyWith(endMinutes: time));
                                        }
                                      }),
                                  _number('Required Work Time (minutes)',
                                      _required),
                                  _number(
                                      'Late Arrival Grace (minutes)', _grace),
                                  _number('Paid Break Allowance (minutes)',
                                      _paidBreak),
                                  Text(
                                      'Work time excludes breaks beyond the paid allowance. Overnight shifts are supported. Timezone: ${AttendanceClock.timezone}.',
                                      style: TextStyle(
                                          color: nec.textTertiary,
                                          fontSize: 12,
                                          height: 1.5)),
                                ])),
                                const AttendanceHeading('Weekly off days'),
                                AttendanceCard(
                                    child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: List.generate(
                                            7,
                                            (index) => FilterChip(
                                                label: Text([
                                                  'Mon',
                                                  'Tue',
                                                  'Wed',
                                                  'Thu',
                                                  'Fri',
                                                  'Sat',
                                                  'Sun'
                                                ][index]),
                                                selected: _policy.offWeekdays
                                                    .contains(index + 1),
                                                onSelected: (selected) {
                                                  final days = List<int>.of(
                                                      _policy.offWeekdays);
                                                  if (selected) {
                                                    days.add(index + 1);
                                                  } else {
                                                    days.remove(index + 1);
                                                  }
                                                  setState(() => _policy =
                                                      _policy.copyWith(
                                                          offWeekdays: days));
                                                })))),
                                const AttendanceHeading('Request rules'),
                                AttendanceCard(
                                    child: Column(children: [
                                  _number(
                                      'Attendance Fix Window (days)', _window),
                                  _toggle(
                                      'Allow work on off days',
                                      'Staff can record work on weekly off days and holidays.',
                                      _policy.allowOffDayWork,
                                      (value) => setState(() => _policy =
                                          _policy.copyWith(
                                              allowOffDayWork: value))),
                                  _toggle(
                                      'Allow backdated leave',
                                      'Staff can submit leave for past dates.',
                                      _policy.allowBackdatedLeave,
                                      (value) => setState(() => _policy =
                                          _policy.copyWith(
                                              allowBackdatedLeave: value))),
                                  _toggle(
                                      'Require overtime approval',
                                      'Extra time appears as approved overtime after admin review.',
                                      _policy.overtimeApprovalRequired,
                                      (value) => setState(() => _policy =
                                          _policy.copyWith(
                                              overtimeApprovalRequired:
                                                  value))),
                                  AttendancePickerRow(
                                      label: 'Attendance Tracking Begins',
                                      value: AttendanceClock.dayLabel(
                                          _policy.trackingStart),
                                      icon: CupertinoIcons.calendar,
                                      onTap: () async {
                                        final date = await pickAttendanceDate(
                                            context,
                                            AttendanceClock.date(
                                                _policy.trackingStart),
                                            last: AttendanceClock.today);
                                        if (mounted && date != null) {
                                          setState(() => _policy =
                                              _policy.copyWith(
                                                  trackingStart:
                                                      AttendanceClock.key(
                                                          date)));
                                        }
                                      }),
                                ])),
                                AttendanceHeading('Leave types',
                                    trailing: CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _leaveType(),
                                        child: Icon(CupertinoIcons.add_circled,
                                            color: nec.brand, size: 23))),
                                AttendanceCard(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                        children: _policy.leaveTypes
                                            .map((type) => ListTile(
                                                title: Text(type.name,
                                                    style: TextStyle(
                                                        color: nec.textPrimary,
                                                        fontSize: 15)),
                                                subtitle: Text(
                                                    '${type.annualDays == null ? 'Unlimited' : '${type.annualDays} days / year'} · ${type.paid ? 'Paid' : 'Unpaid'}',
                                                    style: TextStyle(
                                                        color: nec.textTertiary,
                                                        fontSize: 12)),
                                                trailing: CupertinoSwitch(
                                                    value: type.enabled,
                                                    onChanged: (value) =>
                                                        setState(() => _policy =
                                                            _policy.copyWith(
                                                                leaveTypes: _policy.leaveTypes.map((item) => item.id == type.id ? LeaveType(id: type.id, name: type.name, annualDays: type.annualDays, paid: type.paid, enabled: value) : item).toList()))),
                                                onTap: () => _leaveType(type)))
                                            .toList())),
                                const SizedBox(height: 10),
                                Text(
                                    'Tap to edit a leave type. Disable a type to stop new requests while preserving history. Allowances reset by calendar year.',
                                    style: TextStyle(
                                        color: nec.textTertiary,
                                        fontSize: 12,
                                        height: 1.5)),
                                AttendanceHeading('Holidays',
                                    trailing: CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _holiday(),
                                        child: Icon(CupertinoIcons.add_circled,
                                            color: nec.brand, size: 23))),
                                if (_policy.holidays.isEmpty)
                                  const AttendanceEmpty(
                                      title: 'No holidays configured',
                                      message:
                                          'Add company holidays to exclude them from leave-day calculations.')
                                else
                                  AttendanceCard(
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                          children: _policy.holidays
                                              .map((holiday) => ListTile(
                                                  title: Text(holiday.name,
                                                      style: TextStyle(
                                                          color:
                                                              nec.textPrimary,
                                                          fontSize: 15)),
                                                  subtitle:
                                                      Text(AttendanceClock.dayLabel(holiday.day),
                                                          style: TextStyle(
                                                              color: nec
                                                                  .textTertiary,
                                                              fontSize: 12)),
                                                  trailing: IconButton(
                                                      tooltip: 'Remove holiday',
                                                      icon: Icon(
                                                          CupertinoIcons.minus_circle,
                                                          color: nec.textTertiary),
                                                      onPressed: () => setState(() => _policy = _policy.copyWith(holidays: _policy.holidays.where((item) => item.day != holiday.day).toList()))),
                                                  onTap: () => _holiday(holiday)))
                                              .toList())),
                                const SizedBox(height: 22),
                                Text(
                                    'Shift settings apply to new check-ins. Existing records retain their shift targets, and existing leave requests retain their original day counts.',
                                    style: TextStyle(
                                        color: nec.textSecondary,
                                        fontSize: 12,
                                        height: 1.5)),
                                const SizedBox(height: 20),
                                if (_error != null)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Text(_error!,
                                          style: const TextStyle(
                                              color:
                                                  CupertinoColors.systemRed))),
                                NecButton(
                                    label: 'Save Settings',
                                    fullWidth: true,
                                    loading: _saving,
                                    onPressed: _save),
                                const AttendancePolicyHistory(),
                              ]))),
                ))));
  }
}

class _LeaveTypeEditor extends StatefulWidget {
  final LeaveType? original;

  const _LeaveTypeEditor({this.original});

  @override
  State<_LeaveTypeEditor> createState() => _LeaveTypeEditorState();
}

class _LeaveTypeEditorState extends State<_LeaveTypeEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _days;
  bool _paid = true;
  bool _unlimited = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.original?.name ?? '');
    _days = TextEditingController(text: '${widget.original?.annualDays ?? 10}');
    _paid = widget.original?.paid ?? true;
    _unlimited = widget.original != null && widget.original!.annualDays == null;
  }

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
      key: _form,
      child: AttendanceSheetBody(title: 'Leave Type', children: [
        AttendanceField(
            label: 'Name *',
            controller: _name,
            hint: 'e.g. Maternity leave',
            validator: (value) => (value?.trim().length ?? 0) > 1
                ? null
                : 'Enter a leave type name.'),
        SwitchListTile.adaptive(
            title: const Text('Paid leave'),
            value: _paid,
            onChanged: (value) => setState(() => _paid = value)),
        SwitchListTile.adaptive(
            title: const Text('Unlimited allowance'),
            value: _unlimited,
            onChanged: (value) => setState(() => _unlimited = value)),
        const SizedBox(height: 16),
        if (!_unlimited)
          AttendanceField(
              label: 'Annual Allowance (days)',
              controller: _days,
              keyboardType: TextInputType.number,
              validator: (value) => (int.tryParse(value ?? '') ?? -1) >= 0
                  ? null
                  : 'Enter zero or more days.'),
        NecButton(
            label: 'Save Leave Type',
            fullWidth: true,
            onPressed: () {
              if (!(_form.currentState?.validate() ?? false)) {
                return;
              }
              Navigator.pop(
                  context,
                  LeaveType(
                      id: widget.original?.id ??
                          'type_${AttendanceClock.now.microsecondsSinceEpoch}',
                      name: _name.text.trim(),
                      annualDays: _unlimited ? null : int.parse(_days.text),
                      paid: _paid,
                      enabled: widget.original?.enabled ?? true));
            }),
      ]));
}

class _HolidayEditor extends StatefulWidget {
  final AttendanceHoliday? original;

  const _HolidayEditor({this.original});

  @override
  State<_HolidayEditor> createState() => _HolidayEditorState();
}

class _HolidayEditorState extends State<_HolidayEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _day;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.original?.name ?? '');
    _day = widget.original?.day ?? AttendanceClock.key(AttendanceClock.today);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
      key: _form,
      child: AttendanceSheetBody(title: 'Company Holiday', children: [
        AttendanceField(
            label: 'Holiday Name *',
            controller: _name,
            validator: (value) => (value?.trim().length ?? 0) > 1
                ? null
                : 'Enter a holiday name.'),
        AttendancePickerRow(
            label: 'Date',
            value: AttendanceClock.dayLabel(_day),
            icon: CupertinoIcons.calendar,
            onTap: () async {
              final date =
                  await pickAttendanceDate(context, AttendanceClock.date(_day));
              if (mounted && date != null) {
                setState(() => _day = AttendanceClock.key(date));
              }
            }),
        NecButton(
            label: 'Save Holiday',
            fullWidth: true,
            onPressed: () {
              if (!(_form.currentState?.validate() ?? false)) {
                return;
              }
              Navigator.pop(context,
                  AttendanceHoliday(day: _day, name: _name.text.trim()));
            }),
      ]));
}
