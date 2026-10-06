import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../data/attendance_clock.dart';
import '../../data/attendance_store.dart';
import '../../domain/models/attendance_models.dart';
import 'attendance_ui.dart';
import 'attendance_pickers.dart';

class AttendanceRequestForm extends StatefulWidget {
  final String employeeId;
  final String? actorId;
  final AttendanceRequestKind kind;
  final String? day;

  const AttendanceRequestForm(
      {super.key,
      required this.employeeId,
      required this.kind,
      this.actorId,
      this.day});

  @override
  State<AttendanceRequestForm> createState() => _AttendanceRequestFormState();
}

class _AttendanceRequestFormState extends State<AttendanceRequestForm> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _overtime = TextEditingController();
  final _store = AttendanceStore.instance;
  late String _day;
  late String _endDay;
  String? _typeId;
  bool _halfDay = false;
  String _halfPart = 'First half';
  bool _nextDay = false;
  late int _inMinutes;
  late int _outMinutes;
  bool _saving = false;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _day = widget.day ?? AttendanceClock.key(AttendanceClock.today);
    _endDay = _day;
    _typeId =
        _store.policy.leaveTypes.where((type) => type.enabled).firstOrNull?.id;
    if (widget.kind == AttendanceRequestKind.offDaySwap && widget.day == null) {
      var date = AttendanceClock.today;
      for (var index = 0; index < 7; index++) {
        if (_store.policy.offWeekdays.contains(date.weekday)) {
          break;
        }
        date = date.add(const Duration(days: 1));
      }
      _day = AttendanceClock.key(date);
      do {
        date = date.add(const Duration(days: 1));
      } while (
          !_store.isWorkingDay(widget.employeeId, AttendanceClock.key(date)) &&
              date.difference(AttendanceClock.today).inDays < 14);
      _endDay = AttendanceClock.key(date);
    }
    if (widget.kind == AttendanceRequestKind.overtime && widget.day == null) {
      final eligible = _store.state.records
          .where((record) =>
              record.employeeId == widget.employeeId &&
              record.checkOut != null &&
              _store.dayFor(widget.employeeId, record.day).overtimeMinutes >
                  0 &&
              !_store.requestsFor(widget.employeeId).any((request) =>
                  request.kind == AttendanceRequestKind.overtime &&
                  request.day == record.day &&
                  request.reserves))
          .toList()
        ..sort((a, b) => b.day.compareTo(a.day));
      if (eligible.isNotEmpty) {
        _day = eligible.first.day;
      }
      _endDay = _day;
    }
    _resetTimes();
    _overtime.text =
        _store.dayFor(widget.employeeId, _day).overtimeMinutes.toString();
  }

  void _resetTimes() {
    final record = _store.recordFor(widget.employeeId, _day);
    final offset = record?.offsetMinutes ?? AttendanceClock.offsetMinutes;
    final storedIn = record?.checkIn;
    final storedOut = record?.checkOut;
    final checkIn =
        storedIn == null ? null : AttendanceClock.wallTime(storedIn, offset);
    final checkOut =
        storedOut == null ? null : AttendanceClock.wallTime(storedOut, offset);
    _inMinutes = checkIn == null
        ? _store.policy.startMinutes
        : checkIn.hour * 60 + checkIn.minute;
    _outMinutes = checkOut == null
        ? _store.policy.endMinutes
        : checkOut.hour * 60 + checkOut.minute;
    _nextDay = checkOut == null
        ? _store.policy.overnight
        : AttendanceClock.key(checkOut) != _day;
  }

  @override
  void dispose() {
    _reason.dispose();
    _overtime.dispose();
    super.dispose();
  }

  Future<void> _pickDay(bool end) async {
    final result = await pickAttendanceDate(
        context, AttendanceClock.date(end ? _endDay : _day),
        last: widget.kind == AttendanceRequestKind.correction ||
                widget.kind == AttendanceRequestKind.overtime
            ? AttendanceClock.today
            : null);
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      if (end) {
        _endDay = AttendanceClock.key(result);
      } else {
        _day = AttendanceClock.key(result);
        if (_halfDay ||
            _endDay.compareTo(_day) < 0 ||
            widget.kind != AttendanceRequestKind.leave &&
                widget.kind != AttendanceRequestKind.offDaySwap) {
          _endDay = _day;
        }
        _resetTimes();
        _overtime.text =
            _store.dayFor(widget.employeeId, _day).overtimeMinutes.toString();
      }
      _error = null;
    });
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
      final offset = _store.recordFor(widget.employeeId, _day)?.offsetMinutes ??
          AttendanceClock.offsetMinutes;
      await _store.submitRequest(
          employeeId: widget.employeeId,
          actorId: widget.actorId,
          kind: widget.kind,
          day: _day,
          endDay: _endDay,
          reason: _reason.text,
          typeId: _typeId ?? '',
          halfDay: _halfDay,
          halfDayPart: _halfPart,
          proposedIn: widget.kind == AttendanceRequestKind.correction
              ? AttendanceClock.instant(_day, _inMinutes, offset)
              : null,
          proposedOut: widget.kind == AttendanceRequestKind.correction
              ? AttendanceClock.instant(
                  _day, _outMinutes + (_nextDay ? 1440 : 0), offset)
              : null,
          overtimeMinutes: int.tryParse(_overtime.text) ?? 0);
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
            : 'Unable to submit. Please try again.');
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
    final type = _store.policy.leaveTypes
        .where((type) => type.id == _typeId)
        .firstOrNull;
    String? leaveSummary;
    if (widget.kind == AttendanceRequestKind.leave) {
      try {
        final units =
            _store.calculateLeave(widget.employeeId, _day, _endDay, _halfDay);
        final days = units.values.fold(0, (sum, value) => sum + value) / 2;
        leaveSummary =
            '$days working day${days == 1 ? '' : 's'} · weekly off days and holidays excluded';
      } on FormatException catch (error) {
        leaveSummary = error.message;
      }
    }
    return PopScope(
        canPop: !_saving || _completed,
        child: AbsorbPointer(
            absorbing: _saving,
            child: Form(
                key: _form,
                child: AttendanceSheetBody(
                    title: 'Request ${widget.kind.label}',
                    children: [
                      if (widget.kind == AttendanceRequestKind.leave) ...[
                        AttendancePickerRow(
                            label: 'Leave Type',
                            value: type?.name ?? 'No active leave types',
                            onTap: () async {
                              final value = await chooseAttendanceOption(
                                  context,
                                  'Leave type',
                                  _store.policy.leaveTypes
                                      .where((type) => type.enabled)
                                      .map((type) => (
                                            type.id,
                                            '${type.name}${type.paid ? '' : ' · Unpaid'}'
                                          ))
                                      .toList());
                              if (mounted && value != null) {
                                setState(() => _typeId = value);
                              }
                            }),
                        if (type != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                  'Available in ${AttendanceClock.date(_day).year}: ${_store.balance(widget.employeeId, type, AttendanceClock.date(_day).year).remaining?.toString() ?? 'Unlimited'} days. Pending requests reserve balance.',
                                  style: TextStyle(
                                      color: nec.textSecondary,
                                      fontSize: 12,
                                      height: 1.5))),
                      ],
                      AttendancePickerRow(
                          label: widget.kind == AttendanceRequestKind.offDaySwap
                              ? 'Original Weekly Off Day'
                              : 'Date',
                          value: AttendanceClock.dayLabel(_day),
                          icon: CupertinoIcons.calendar,
                          onTap: () => _pickDay(false)),
                      if (widget.kind == AttendanceRequestKind.leave ||
                          widget.kind == AttendanceRequestKind.offDaySwap)
                        AttendancePickerRow(
                            label:
                                widget.kind == AttendanceRequestKind.offDaySwap
                                    ? 'Replacement Off Day'
                                    : 'Through',
                            value: AttendanceClock.dayLabel(_endDay),
                            icon: CupertinoIcons.calendar,
                            onTap: _halfDay ? () {} : () => _pickDay(true)),
                      if (widget.kind == AttendanceRequestKind.leave) ...[
                        Row(children: [
                          Expanded(
                              child: Text('Half-day leave',
                                  style: TextStyle(color: nec.textPrimary))),
                          CupertinoSwitch(
                              value: _halfDay,
                              onChanged: (value) => setState(() {
                                    _halfDay = value;
                                    if (value) {
                                      _endDay = _day;
                                    }
                                  }))
                        ]),
                        if (_halfDay)
                          AttendancePickerRow(
                              label: 'Part of Day',
                              value: _halfPart,
                              onTap: () async {
                                final value = await chooseAttendanceOption(
                                    context, 'Part of day', [
                                  ('First half', 'First half'),
                                  ('Second half', 'Second half')
                                ]);
                                if (mounted && value != null) {
                                  setState(() => _halfPart = value);
                                }
                              }),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(leaveSummary ?? '',
                                style: TextStyle(
                                    color: nec.textSecondary,
                                    fontSize: 13,
                                    height: 1.5))),
                      ],
                      if (widget.kind == AttendanceRequestKind.correction) ...[
                        AttendancePickerRow(
                            label: 'Correct Check-in',
                            value: AttendanceClock.minutesTime(_inMinutes),
                            icon: CupertinoIcons.clock,
                            onTap: () async {
                              final time =
                                  await pickAttendanceTime(context, _inMinutes);
                              if (mounted && time != null) {
                                setState(() => _inMinutes = time);
                              }
                            }),
                        AttendancePickerRow(
                            label: 'Correct Check-out',
                            value: AttendanceClock.minutesTime(_outMinutes),
                            icon: CupertinoIcons.clock,
                            onTap: () async {
                              final time = await pickAttendanceTime(
                                  context, _outMinutes);
                              if (mounted && time != null) {
                                setState(() => _outMinutes = time);
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
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                                'The current record stays unchanged until an administrator approves this request.',
                                style: TextStyle(
                                    color: nec.textSecondary,
                                    fontSize: 13,
                                    height: 1.5))),
                      ],
                      if (widget.kind == AttendanceRequestKind.offDaySwap)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                                'After approval, the original off day becomes a working day for you and the replacement date becomes your off day.',
                                style: TextStyle(
                                    color: nec.textSecondary,
                                    fontSize: 13,
                                    height: 1.5))),
                      if (widget.kind == AttendanceRequestKind.overtime) ...[
                        AttendanceValues(rows: [
                          (
                            'Recorded extra work',
                            AttendanceClock.duration(_store
                                .dayFor(widget.employeeId, _day)
                                .overtimeMinutes)
                          )
                        ]),
                        const SizedBox(height: 16),
                        AttendanceField(
                            label: 'Overtime to Approve (minutes)',
                            controller: _overtime,
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                (int.tryParse(value ?? '') ?? 0) > 0
                                    ? null
                                    : 'Enter the number of extra minutes.'),
                      ],
                      AttendanceField(
                          label: 'Reason *',
                          controller: _reason,
                          maxLines: 3,
                          hint: 'Explain the request for your administrator',
                          validator: (value) => (value?.trim().length ?? 0) >= 5
                              ? null
                              : 'Provide at least 5 characters.'),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 13))),
                      NecButton(
                          label: 'Send Request',
                          fullWidth: true,
                          loading: _saving,
                          onPressed:
                              widget.kind == AttendanceRequestKind.leave &&
                                      type == null
                                  ? null
                                  : _save),
                    ]))));
  }
}
