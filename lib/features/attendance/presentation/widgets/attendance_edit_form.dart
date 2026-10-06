import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../data/attendance_clock.dart';
import '../../data/attendance_store.dart';
import '../../../team/data/employee_store.dart';
import 'attendance_pickers.dart';
import 'attendance_ui.dart';

class AttendanceEditForm extends StatefulWidget {
  final String employeeId;
  final String day;
  final String actorId;

  const AttendanceEditForm(
      {super.key,
      required this.employeeId,
      required this.day,
      required this.actorId});

  @override
  State<AttendanceEditForm> createState() => _AttendanceEditFormState();
}

class _AttendanceEditFormState extends State<AttendanceEditForm> {
  final _note = TextEditingController();
  final _form = GlobalKey<FormState>();
  late String _day;
  late int _in;
  late int _out;
  bool _absent = false;
  bool _nextDay = false;
  bool _saving = false;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _day = widget.day;
    _fill();
  }

  void _fill() {
    final record = AttendanceStore.instance.recordFor(widget.employeeId, _day);
    final storedIn = record?.checkIn;
    final storedOut = record?.checkOut;
    final first = storedIn == null
        ? null
        : AttendanceClock.wallTime(storedIn, record?.offsetMinutes);
    final last = storedOut == null
        ? null
        : AttendanceClock.wallTime(storedOut, record?.offsetMinutes);
    _in = first == null
        ? AttendanceStore.instance.policy.startMinutes
        : first.hour * 60 + first.minute;
    _out = last == null
        ? AttendanceStore.instance.policy.endMinutes
        : last.hour * 60 + last.minute;
    _nextDay = last == null
        ? AttendanceStore.instance.policy.overnight
        : AttendanceClock.key(last) != _day;
    _absent = record != null && record.checkIn == null;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final offset = AttendanceStore.instance
              .recordFor(widget.employeeId, _day)
              ?.offsetMinutes ??
          AttendanceClock.offsetMinutes;
      await AttendanceStore.instance.setAttendance(
          employeeId: widget.employeeId,
          day: _day,
          actorId: widget.actorId,
          note: _note.text,
          checkIn: _absent ? null : AttendanceClock.instant(_day, _in, offset),
          checkOut: _absent
              ? null
              : AttendanceClock.instant(
                  _day, _out + (_nextDay ? 1440 : 0), offset));
      if (mounted) {
        setState(() => _completed = true);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message
            : 'Unable to save this attendance change.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return PopScope(
        canPop: !_saving || _completed,
        child: AbsorbPointer(
            absorbing: _saving,
            child: Form(
                key: _form,
                child:
                    AttendanceSheetBody(title: 'Manage Attendance', children: [
                  Text(
                      EmployeeStore.instance.byId(widget.employeeId)?.name ??
                          'Employee',
                      style: TextStyle(
                          color: nec.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  AttendancePickerRow(
                      label: 'Date',
                      value: AttendanceClock.dayLabel(_day),
                      icon: CupertinoIcons.calendar,
                      onTap: () async {
                        final date = await pickAttendanceDate(
                            context, AttendanceClock.date(_day),
                            last: AttendanceClock.today);
                        if (mounted && date != null) {
                          setState(() {
                            _day = AttendanceClock.key(date);
                            _fill();
                          });
                        }
                      }),
                  AttendancePickerRow(
                      label: 'Record Type',
                      value: _absent ? 'Mark absent' : 'Recorded attendance',
                      onTap: () async {
                        final value = await chooseAttendanceOption(
                            context, 'Record type', [
                          ('attendance', 'Recorded attendance'),
                          ('absent', 'Mark absent')
                        ]);
                        if (mounted && value != null) {
                          setState(() => _absent = value == 'absent');
                        }
                      }),
                  if (!_absent) ...[
                    AttendancePickerRow(
                        label: 'Check-in',
                        value: AttendanceClock.minutesTime(_in),
                        icon: CupertinoIcons.clock,
                        onTap: () async {
                          final value = await pickAttendanceTime(context, _in);
                          if (mounted && value != null) {
                            setState(() => _in = value);
                          }
                        }),
                    AttendancePickerRow(
                        label: 'Check-out',
                        value: AttendanceClock.minutesTime(_out),
                        icon: CupertinoIcons.clock,
                        onTap: () async {
                          final value = await pickAttendanceTime(context, _out);
                          if (mounted && value != null) {
                            setState(() => _out = value);
                          }
                        }),
                    Row(children: [
                      Expanded(
                          child: Text('Check-out is the next day',
                              style: TextStyle(color: nec.textPrimary))),
                      CupertinoSwitch(
                          value: _nextDay,
                          onChanged: (value) =>
                              setState(() => _nextDay = value))
                    ]),
                    const SizedBox(height: 16),
                  ],
                  AttendanceField(
                      label: 'Reason for Change *',
                      controller: _note,
                      maxLines: 3,
                      validator: (value) => (value?.trim().length ?? 0) >= 5
                          ? null
                          : 'Provide a reason of at least 5 characters.'),
                  Text(
                      'Original values and the administrator responsible for this change are retained in history.',
                      style: TextStyle(
                          color: nec.textSecondary, fontSize: 12, height: 1.5)),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: CupertinoColors.systemRed))),
                  NecButton(
                      label: 'Save Attendance',
                      fullWidth: true,
                      loading: _saving,
                      onPressed: _save),
                ]))));
  }
}
