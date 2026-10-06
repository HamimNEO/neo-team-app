import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../team/data/employee_store.dart';
import '../../team/domain/models/employee.dart';
import '../../settings/data/system_settings_store.dart';
import '../domain/models/attendance_models.dart';
import 'attendance_clock.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';

/// Local UI repository. Production must authorize actors and timestamp punches
/// on the server using the authenticated employee, rather than client IDs/time.
class AttendanceStore extends ChangeNotifier {
  AttendanceStore._();

  static final instance = AttendanceStore._();
  static const _key = 'nec_attendance_v1';
  late AttendanceState _state = AttendanceState(
      policy: AttendancePolicy(
          trackingStart: AttendanceClock.key(AttendanceClock.today)));
  Future<void>? _loading;
  Future<void> _pending = Future.value();
  String? loadError;

  AttendanceState get state => _state;

  AttendancePolicy get policy => _state.policy;

  bool isAdministrator(String id) {
    return DemoSession.instance.isAdmin &&
        id == DemoSession.instance.employeeId;
  }

  String? get administratorId =>
      DemoSession.instance.isAdmin ? DemoSession.instance.employeeId : null;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      await SystemSettingsStore.instance.load();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        if (json['version'] != 1) {
          throw const FormatException('Unsupported attendance data');
        }
        _state = AttendanceState.fromJson(json).copyWith();
      } else {
        _state = AttendanceState(
            policy: AttendancePolicy(
                trackingStart: AttendanceClock.key(AttendanceClock.today)));
        if (!await prefs.setString(_key, jsonEncode(_state.toJson()))) {
          throw const FormatException(
              'Unable to initialize attendance storage.');
        }
      }
    } catch (_) {
      loadError =
          'Attendance data could not be loaded. Restart the app before making changes.';
    }
  }

  Employee _employee(String id) {
    final employee = EmployeeStore.instance.byId(id);
    if (employee == null) {
      throw const FormatException('Employee not found.');
    }
    return employee;
  }

  void _authorize(String actorId, String employeeId, {bool adminOnly = false}) {
    if (!DemoSession.instance.signedIn ||
        actorId != DemoSession.instance.employeeId) {
      throw const FormatException(
          'Use your signed-in account for this action.');
    }
    if (!DemoSession.instance.isAdmin &&
        !StaffAccessStore.instance.allows(StaffPermission.attendance)) {
      throw const FormatException(
          'Attendance access is disabled by your administrator.');
    }
    if (_employee(actorId).status != 'Active' &&
        !DemoSession.instance.isAdmin) {
      throw const FormatException('An active account is required.');
    }
    if ((adminOnly || actorId != employeeId) && !isAdministrator(actorId)) {
      throw const FormatException('Administrator access is required.');
    }
  }

  Future<void> _commit(String actorId, String employeeId, String day,
      String title, AttendanceState Function(AttendanceState) transform,
      {bool adminOnly = false}) async {
    await load();
    final write = _pending.then((_) async {
      if (loadError != null) {
        throw FormatException(loadError!);
      }
      _authorize(actorId, employeeId, adminOnly: adminOnly);
      final next = transform(_state);
      final changedRequest = next.requests.where((request) {
        final previous = requestById(request.id);
        return previous == null || previous.status != request.status;
      }).firstOrNull;
      final updated = next.copyWith(events: [
        ...next.events,
        AttendanceEvent(
          employeeId: employeeId,
          actorId: actorId,
          day: day,
          title: title,
          at: AttendanceClock.now,
          requestBefore: changedRequest == null
              ? null
              : requestById(changedRequest.id)?.toJson(),
          requestAfter: changedRequest?.toJson(),
          before: employeeId.isEmpty
              ? _state.policy.toJson()
              : _state.records
                  .where((record) =>
                      record.employeeId == employeeId && record.day == day)
                  .firstOrNull
                  ?.toJson(),
          after: employeeId.isEmpty
              ? next.policy.toJson()
              : next.records
                  .where((record) =>
                      record.employeeId == employeeId && record.day == day)
                  .firstOrNull
                  ?.toJson(),
        )
      ]);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_key, jsonEncode(updated.toJson()))) {
        throw const FormatException(
            'Changes could not be saved. Please try again.');
      }
      _state = updated;
      notifyListeners();
    });
    _pending = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    await write;
  }

  AttendanceRecord? recordFor(String employeeId, String day) => _state.records
      .where((record) => record.employeeId == employeeId && record.day == day)
      .firstOrNull;

  AttendanceRecord? activeRecord(String employeeId) => _state.records
      .where((record) => record.employeeId == employeeId && record.open)
      .firstOrNull;

  List<AttendanceRequest> requestsFor(String employeeId) => _state.requests
      .where((request) => request.employeeId == employeeId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<AttendanceRequest> get allRequests => List.of(_state.requests)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  AttendanceRequest? requestById(String id) =>
      _state.requests.where((request) => request.id == id).firstOrNull;

  List<AttendanceRequest> _approved(
          String employeeId, AttendanceRequestKind kind) =>
      _state.requests
          .where((request) =>
              request.employeeId == employeeId &&
              request.kind == kind &&
              request.status == AttendanceRequestStatus.approved)
          .toList();

  bool swappedOff(String id, String day) =>
      _approved(id, AttendanceRequestKind.offDaySwap)
          .any((request) => request.endDay == day);

  bool swappedWork(String id, String day) =>
      _approved(id, AttendanceRequestKind.offDaySwap)
          .any((request) => request.day == day);

  bool isWorkingDay(String employeeId, String day) {
    if (swappedOff(employeeId, day)) {
      return false;
    }
    if (swappedWork(employeeId, day)) {
      return true;
    }
    return !policy.offWeekdays.contains(AttendanceClock.date(day).weekday) &&
        !policy.holidays.any((holiday) => holiday.day == day);
  }

  int leaveUnits(String employeeId, String day) =>
      _approved(employeeId, AttendanceRequestKind.leave)
          .fold(0, (total, request) => total + (request.leaveUnits[day] ?? 0));

  LeaveBalance balance(String employeeId, LeaveType type, int year,
      {String? excluding}) {
    var used = 0;
    var pending = 0;
    for (final request in requestsFor(employeeId)) {
      if (request.id == excluding ||
          request.kind != AttendanceRequestKind.leave ||
          request.typeId != type.id) {
        continue;
      }
      final units = request.leaveUnits.entries
          .where((entry) => entry.key.startsWith('$year-'))
          .fold(0, (total, entry) => total + entry.value);
      if (request.status == AttendanceRequestStatus.approved) {
        used += units;
      }
      if (request.status == AttendanceRequestStatus.pending) {
        pending += units;
      }
    }
    return LeaveBalance(type, used / 2, pending / 2);
  }

  DateTime _joined(Employee employee) {
    final iso = DateTime.tryParse(employee.joinedDate);
    if (iso != null) {
      return DateTime.utc(iso.year, iso.month, iso.day);
    }
    for (final format in ['dd MMMM yyyy', 'dd MMM yyyy']) {
      try {
        return DateFormat(format).parseStrict(employee.joinedDate, true);
      } on FormatException {
        continue;
      }
    }
    return DateTime.utc(1900);
  }

  AttendanceDay dayFor(String employeeId, String day, {DateTime? now}) {
    final moment = now ?? AttendanceClock.now;
    final today = AttendanceClock.key(AttendanceClock.wallTime(moment));
    final record = recordFor(employeeId, day);
    final leave = leaveUnits(employeeId, day) / 2;
    final approved = _approved(employeeId, AttendanceRequestKind.overtime)
        .where((request) => request.day == day)
        .fold(0, (sum, request) => sum + request.overtimeMinutes);
    if (record != null) {
      if (record.checkIn == null && leave == 1) {
        return AttendanceDay(
            day: day,
            status: AttendanceStatus.leave,
            record: record,
            leaveDays: leave,
            note: record.note);
      }
      final isWork = (record.wasWorkingDay || swappedWork(employeeId, day)) &&
          !swappedOff(employeeId, day);
      final target = isWork
          ? (record.requiredMinutes * (1 - leave))
              .round()
              .clamp(0, 1440)
              .toInt()
          : 0;
      final worked = record.workedSeconds(moment) ~/ 60;
      var expected = record.expectedStart;
      if (_approved(employeeId, AttendanceRequestKind.leave).any((request) =>
          request.leaveUnits[day] == 1 &&
          request.halfDayPart == 'First half')) {
        expected = expected.add(Duration(minutes: record.shiftMinutes ~/ 2));
      }
      final late = record.checkIn == null || !isWork
          ? 0
          : math.max(0, record.checkIn!.difference(expected).inMinutes);
      final extra = math.max(0, worked - target);
      final status = record.checkIn == null
          ? AttendanceStatus.absent
          : record.open
              ? (record.onBreak
                  ? AttendanceStatus.onBreak
                  : AttendanceStatus.working)
              : worked >= target
                  ? (late > record.graceMinutes
                      ? AttendanceStatus.late
                      : AttendanceStatus.present)
                  : worked >= (target / 2).ceil()
                      ? AttendanceStatus.halfDay
                      : AttendanceStatus.shortDay;
      return AttendanceDay(
          day: day,
          status: status,
          record: record,
          workedMinutes: worked,
          requiredMinutes: target,
          overtimeMinutes: extra,
          approvedOvertimeMinutes:
              policy.overtimeApprovalRequired ? approved : extra,
          lateMinutes: late > record.graceMinutes ? late : 0,
          leaveDays: leave,
          note: record.note);
    }
    if (leave == 1) {
      return AttendanceDay(
          day: day, status: AttendanceStatus.leave, leaveDays: leave);
    }
    if (swappedOff(employeeId, day)) {
      return AttendanceDay(day: day, status: AttendanceStatus.swappedOff);
    }
    final holiday =
        policy.holidays.where((item) => item.day == day).firstOrNull;
    if (holiday != null && !swappedWork(employeeId, day)) {
      return AttendanceDay(
          day: day, status: AttendanceStatus.holiday, note: holiday.name);
    }
    if (!isWorkingDay(employeeId, day)) {
      return AttendanceDay(day: day, status: AttendanceStatus.offDay);
    }
    if (day.compareTo(policy.trackingStart) < 0 ||
        AttendanceClock.date(day).isBefore(_joined(_employee(employeeId)))) {
      return AttendanceDay(day: day, status: AttendanceStatus.notTracked);
    }
    if (day.compareTo(today) > 0) {
      return AttendanceDay(
          day: day, status: AttendanceStatus.upcoming, leaveDays: leave);
    }
    final end =
        AttendanceClock.instant(day, policy.startMinutes + policy.shiftMinutes);
    return AttendanceDay(
        day: day,
        leaveDays: leave,
        status: day == today && moment.isBefore(end)
            ? AttendanceStatus.notCheckedIn
            : AttendanceStatus.absent,
        note: leave == 0.5 ? 'Half-day leave approved' : '');
  }

  List<AttendanceDay> monthFor(String employeeId, DateTime month) =>
      AttendanceClock.monthDays(month)
          .map((date) => dayFor(employeeId, AttendanceClock.key(date)))
          .toList();

  AttendanceState _withRecord(AttendanceState state, AttendanceRecord record) =>
      state.copyWith(records: [
        ...state.records.where((item) =>
            !(item.employeeId == record.employeeId && item.day == record.day)),
        record
      ]);

  AttendanceRecord _newRecord(String employeeId, String day,
          {DateTime? checkIn,
          DateTime? checkOut,
          String note = '',
          bool corrected = false,
          int revision = 1,
          int? offsetMinutes,
          AttendanceRecord? original}) =>
      AttendanceRecord(
          employeeId: employeeId,
          day: day,
          checkIn: checkIn,
          checkOut: checkOut,
          offsetMinutes: offsetMinutes ??
              original?.offsetMinutes ??
              AttendanceClock.offsetMinutes,
          requiredMinutes: original?.requiredMinutes ?? policy.requiredMinutes,
          expectedStart: original?.expectedStart ??
              AttendanceClock.instant(day, policy.startMinutes, offsetMinutes),
          shiftMinutes: original?.shiftMinutes ?? policy.shiftMinutes,
          graceMinutes: original?.graceMinutes ?? policy.graceMinutes,
          paidBreakMinutes:
              original?.paidBreakMinutes ?? policy.paidBreakMinutes,
          wasWorkingDay:
              original?.wasWorkingDay ?? isWorkingDay(employeeId, day),
          corrected: corrected,
          note: note,
          revision: revision,
          breaks: _correctedBreaks(original, checkIn, checkOut));

  List<AttendanceBreak> _correctedBreaks(
      AttendanceRecord? original, DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || original == null) {
      return const [];
    }
    final result = <AttendanceBreak>[];
    for (final item in original.breaks) {
      final start = item.start.isBefore(checkIn) ? checkIn : item.start;
      var end = item.end ?? checkOut;
      if (checkOut != null && end != null && end.isAfter(checkOut)) {
        end = checkOut;
      }
      if (checkOut != null && !start.isBefore(checkOut)) {
        continue;
      }
      if (end != null && !end.isAfter(start)) {
        continue;
      }
      result.add(AttendanceBreak(start, end));
    }
    return List.unmodifiable(result);
  }

  String get checkInDay {
    final wall = AttendanceClock.wallTime(AttendanceClock.now);
    return AttendanceClock.key(
        policy.overnight && wall.hour * 60 + wall.minute <= policy.endMinutes
            ? wall.subtract(const Duration(days: 1))
            : wall);
  }

  Future<void> checkIn(String employeeId) =>
      _commit(employeeId, employeeId, checkInDay, 'Checked in', (state) {
        final day = checkInDay;
        if (day.compareTo(policy.trackingStart) < 0 ||
            AttendanceClock.date(day)
                .isBefore(_joined(_employee(employeeId)))) {
          throw const FormatException(
              'Attendance tracking has not started for this date.');
        }
        if (activeRecord(employeeId) != null) {
          throw const FormatException(
              'Check out of your existing session first.');
        }
        if (recordFor(employeeId, day) != null) {
          throw const FormatException(
              'Attendance already exists for this day. Request a fix if needed.');
        }
        if (leaveUnits(employeeId, day) >= 2) {
          throw const FormatException('You have approved leave today.');
        }
        if (!policy.allowOffDayWork && !isWorkingDay(employeeId, day)) {
          throw const FormatException(
              'Check-in on days off is disabled by your administrator.');
        }
        return _withRecord(
            state, _newRecord(employeeId, day, checkIn: AttendanceClock.now));
      });

  Future<void> checkOut(String employeeId) => _commit(
          employeeId,
          employeeId,
          activeRecord(employeeId)?.day ??
              AttendanceClock.key(AttendanceClock.today),
          'Checked out', (state) {
        final record = activeRecord(employeeId);
        if (record == null) {
          throw const FormatException('Check in first.');
        }
        final now = AttendanceClock.now;
        if (now.isBefore(record.checkIn!)) {
          throw const FormatException(
              'Device time changed. Please request an attendance fix.');
        }
        if (now.difference(record.checkIn!).inHours >= 24) {
          throw const FormatException(
              'This session is over 24 hours old. Request a fix to close it.');
        }
        final breaks = record.breaks
            .map((item) => AttendanceBreak(item.start, item.end ?? now));
        return _withRecord(
            state,
            AttendanceRecord.fromJson({
              ...record.toJson(),
              'checkOut': now.toIso8601String(),
              'breaks': breaks.map((item) => item.toJson()).toList(),
              'revision': record.revision + 1
            }));
      });

  Future<void> toggleBreak(String employeeId) => _commit(
          employeeId,
          employeeId,
          activeRecord(employeeId)?.day ??
              AttendanceClock.key(AttendanceClock.today),
          'Break updated', (state) {
        final record = activeRecord(employeeId);
        if (record == null) {
          throw const FormatException('Check in first.');
        }
        final now = AttendanceClock.now;
        final lastTime = record.breaks.isEmpty
            ? record.checkIn!
            : record.breaks.last.end ?? record.breaks.last.start;
        if (now.isBefore(lastTime)) {
          throw const FormatException(
              'Device time changed. Please request an attendance fix.');
        }
        final breaks = List<AttendanceBreak>.of(record.breaks);
        if (record.onBreak) {
          breaks[breaks.length - 1] = AttendanceBreak(breaks.last.start, now);
        } else {
          breaks.add(AttendanceBreak(now));
        }
        return _withRecord(
            state,
            AttendanceRecord.fromJson({
              ...record.toJson(),
              'breaks': breaks.map((item) => item.toJson()).toList(),
              'revision': record.revision + 1
            }));
      });

  Map<String, int> calculateLeave(
      String employeeId, String start, String end, bool halfDay) {
    final first = AttendanceClock.date(start);
    final last = AttendanceClock.date(end);
    if (last.isBefore(first) || last.difference(first).inDays > 366) {
      throw const FormatException(
          'Choose a valid leave period of up to one year.');
    }
    if (halfDay && start != end) {
      throw const FormatException('Half-day leave must be for a single day.');
    }
    final units = <String, int>{};
    for (var date = first;
        !date.isAfter(last);
        date = date.add(const Duration(days: 1))) {
      final day = AttendanceClock.key(date);
      if (isWorkingDay(employeeId, day)) {
        units[day] = halfDay ? 1 : 2;
      }
    }
    if (units.isEmpty) {
      throw const FormatException('This period contains no working days.');
    }
    return units;
  }

  void _checkLeave(AttendanceRequest request) {
    final type = policy.leaveTypes
        .where((item) => item.id == request.typeId)
        .firstOrNull;
    if (type == null) {
      throw const FormatException('Leave type is unavailable.');
    }
    if (_employee(request.employeeId).status != 'Active') {
      throw const FormatException('This employee is inactive.');
    }
    for (final entry in request.leaveUnits.entries) {
      if (AttendanceClock.date(entry.key)
          .isBefore(_joined(_employee(request.employeeId)))) {
        throw const FormatException(
            'Leave cannot be requested before joining.');
      }
      if (entry.value == 2 &&
          recordFor(request.employeeId, entry.key)?.checkIn != null) {
        throw const FormatException(
            'Attendance already exists on a requested full leave day.');
      }
      if (_state.requests.any((other) =>
          other.id != request.id &&
          other.employeeId == request.employeeId &&
          other.reserves &&
          other.kind == AttendanceRequestKind.leave &&
          other.leaveUnits.containsKey(entry.key))) {
        throw const FormatException(
            'A leave request already covers part of this period.');
      }
      if (_state.requests.any((other) =>
          other.employeeId == request.employeeId &&
          other.reserves &&
          other.kind == AttendanceRequestKind.offDaySwap &&
          other.endDay == entry.key)) {
        throw const FormatException(
            'An off-day swap already covers a requested date.');
      }
    }
    for (final year in request.leaveUnits.keys
        .map((day) => AttendanceClock.date(day).year)
        .toSet()) {
      final days = request.leaveUnits.entries
              .where((entry) => AttendanceClock.date(entry.key).year == year)
              .fold(0, (sum, entry) => sum + entry.value) /
          2;
      final available =
          balance(request.employeeId, type, year, excluding: request.id)
              .remaining;
      if (available != null && days > available) {
        throw FormatException('Not enough ${type.name} balance for $year.');
      }
    }
  }

  void _checkCorrection(AttendanceRequest request, {bool approving = false}) {
    final record = recordFor(request.employeeId, request.day);
    if (approving && record?.revision != request.originalRevision) {
      throw const FormatException(
          'Attendance changed after this request. Reject it and ask for a new request.');
    }
    _validateTimes(request.day, request.proposedIn!, request.proposedOut!,
        request.offsetMinutes);
    _validateEmploymentDate(request.employeeId, request.day);
    _validateOverlap(request.employeeId, request.day, request.proposedIn!,
        request.proposedOut!);
    if (leaveUnits(request.employeeId, request.day) == 2) {
      throw const FormatException('This date has approved full-day leave.');
    }
  }

  void _validateEmploymentDate(String employeeId, String day) {
    if (AttendanceClock.date(day).isBefore(_joined(_employee(employeeId)))) {
      throw const FormatException(
          'Attendance cannot be recorded before the employee joined.');
    }
  }

  void _validateOverlap(
      String employeeId, String day, DateTime checkIn, DateTime checkOut) {
    if (_state.records.any((record) =>
        record.employeeId == employeeId &&
        record.day != day &&
        record.checkIn != null &&
        checkIn.isBefore(record.checkOut ?? AttendanceClock.now) &&
        checkOut.isAfter(record.checkIn!))) {
      throw const FormatException(
          'These times overlap an existing attendance session.');
    }
  }

  void _validateTimes(
      String day, DateTime checkIn, DateTime checkOut, int offset) {
    if (AttendanceClock.key(AttendanceClock.wallTime(checkIn, offset)) != day ||
        !checkOut.isAfter(checkIn) ||
        checkOut.difference(checkIn).inMinutes > 1440 ||
        checkOut.isAfter(AttendanceClock.now)) {
      throw const FormatException(
          'Check-in must be on the selected date. Check-out must follow it, within 24 hours and not in the future.');
    }
  }

  void _checkSwap(AttendanceRequest request) {
    _validateEmploymentDate(request.employeeId, request.day);
    _validateEmploymentDate(request.employeeId, request.endDay);
    final workDate = AttendanceClock.date(request.day);
    if (!policy.offWeekdays.contains(workDate.weekday) ||
        !isWorkingDay(request.employeeId, request.endDay) ||
        request.day == request.endDay ||
        request.endDay.compareTo(AttendanceClock.key(AttendanceClock.today)) <
            0) {
      throw const FormatException(
          'Swap a weekly off day for a working day today or in the future.');
    }
    if (workDate.isBefore(AttendanceClock.today
        .subtract(Duration(days: policy.correctionWindowDays)))) {
      throw const FormatException(
          'The original off day is outside the request window.');
    }
    if (recordFor(request.employeeId, request.endDay) != null ||
        leaveUnits(request.employeeId, request.endDay) > 0) {
      throw const FormatException(
          'The replacement off day already has attendance or approved leave.');
    }
    if (_state.requests.any((other) =>
        other.id != request.id &&
        other.employeeId == request.employeeId &&
        other.reserves &&
        ((other.kind == AttendanceRequestKind.offDaySwap &&
                [
                  other.day,
                  other.endDay
                ].any((day) => day == request.day || day == request.endDay)) ||
            (other.kind == AttendanceRequestKind.leave &&
                other.leaveUnits.containsKey(request.endDay))))) {
      throw const FormatException(
          'Another request already covers one of these dates.');
    }
    if (_approved(request.employeeId, AttendanceRequestKind.overtime)
        .any((other) => other.day == request.day)) {
      throw const FormatException(
          'Overtime has already been approved for the original off day.');
    }
  }

  void _checkOvertime(AttendanceRequest request) {
    final record = recordFor(request.employeeId, request.day);
    final day = dayFor(request.employeeId, request.day);
    if (record?.checkOut == null ||
        request.overtimeMinutes <= 0 ||
        request.overtimeMinutes > day.overtimeMinutes) {
      throw const FormatException(
          'Check out first, then request no more than your recorded extra work time.');
    }
  }

  Future<void> submitRequest(
          {required String employeeId,
          String? actorId,
          required AttendanceRequestKind kind,
          required String day,
          String? endDay,
          required String reason,
          String typeId = '',
          bool halfDay = false,
          String halfDayPart = 'First half',
          DateTime? proposedIn,
          DateTime? proposedOut,
          int overtimeMinutes = 0}) =>
      _commit(actorId ?? employeeId, employeeId, day, '${kind.label} requested',
          (state) {
        if (reason.trim().length < 5) {
          throw const FormatException(
              'Please provide a reason of at least 5 characters.');
        }
        if (_employee(employeeId).status != 'Active') {
          throw const FormatException('This employee is inactive.');
        }
        final today = AttendanceClock.key(AttendanceClock.today);
        final type = policy.leaveTypes
            .where((item) => item.id == typeId && item.enabled)
            .firstOrNull;
        if (kind == AttendanceRequestKind.leave && type == null) {
          throw const FormatException('Select an available leave type.');
        }
        if (kind == AttendanceRequestKind.leave &&
            day.compareTo(today) < 0 &&
            !policy.allowBackdatedLeave &&
            !isAdministrator(actorId ?? employeeId)) {
          throw const FormatException(
              'Backdated leave is disabled. Contact your administrator.');
        }
        if (kind == AttendanceRequestKind.correction &&
            (day.compareTo(today) > 0 ||
                day.compareTo(policy.trackingStart) < 0 ||
                AttendanceClock.date(day).isBefore(AttendanceClock.today
                    .subtract(Duration(days: policy.correctionWindowDays))))) {
          throw const FormatException(
              'Choose a tracked date within the attendance fix window.');
        }
        if (kind == AttendanceRequestKind.correction &&
            (proposedIn == null || proposedOut == null)) {
          throw const FormatException(
              'Select the corrected check-in and check-out times.');
        }
        if (kind != AttendanceRequestKind.leave &&
            _state.requests.any((request) =>
                request.employeeId == employeeId &&
                request.kind == kind &&
                request.day == day &&
                request.reserves &&
                (kind != AttendanceRequestKind.correction ||
                    request.status == AttendanceRequestStatus.pending))) {
          throw const FormatException('A request already exists for this day.');
        }
        final request = AttendanceRequest(
            id: 'req_${AttendanceClock.now.microsecondsSinceEpoch}',
            employeeId: employeeId,
            kind: kind,
            day: day,
            endDay: endDay ?? day,
            reason: reason.trim(),
            createdAt: AttendanceClock.now,
            offsetMinutes: recordFor(employeeId, day)?.offsetMinutes ??
                AttendanceClock.offsetMinutes,
            typeId: typeId,
            typeName: type?.name ?? '',
            halfDayPart: halfDay ? halfDayPart : '',
            leaveUnits: kind == AttendanceRequestKind.leave
                ? calculateLeave(employeeId, day, endDay ?? day, halfDay)
                : const {},
            proposedIn: proposedIn,
            proposedOut: proposedOut,
            originalRevision: recordFor(employeeId, day)?.revision,
            originalRecord: recordFor(employeeId, day)?.toJson(),
            overtimeMinutes: overtimeMinutes);
        switch (kind) {
          case AttendanceRequestKind.leave:
            _checkLeave(request);
          case AttendanceRequestKind.correction:
            _checkCorrection(request);
          case AttendanceRequestKind.offDaySwap:
            _checkSwap(request);
          case AttendanceRequestKind.overtime:
            _checkOvertime(request);
        }
        return state.copyWith(requests: [...state.requests, request]);
      });

  Future<void> reviewRequest(String id,
      {required String actorId, required bool approve, required String note}) {
    final initial = requestById(id);
    if (initial == null) {
      return Future.error(const FormatException('Request not found.'));
    }
    return _commit(actorId, initial.employeeId, initial.day,
        '${initial.kind.label} ${approve ? 'approved' : 'rejected'}', (state) {
      final request = requestById(id)!;
      if (request.status != AttendanceRequestStatus.pending) {
        throw const FormatException('This request has already been reviewed.');
      }
      if (!approve && note.trim().length < 5) {
        throw const FormatException('Provide a reason for rejection.');
      }
      var updated = state;
      if (approve) {
        switch (request.kind) {
          case AttendanceRequestKind.leave:
            _checkLeave(request);
          case AttendanceRequestKind.offDaySwap:
            _checkSwap(request);
          case AttendanceRequestKind.overtime:
            _checkOvertime(request);
          case AttendanceRequestKind.correction:
            _checkCorrection(request, approving: true);
            final original = recordFor(request.employeeId, request.day);
            final corrected = _newRecord(request.employeeId, request.day,
                checkIn: request.proposedIn,
                checkOut: request.proposedOut,
                offsetMinutes: request.offsetMinutes,
                original: original,
                note: request.reason,
                corrected: true,
                revision: (original?.revision ?? 0) + 1);
            _ensureOvertimeFits(corrected);
            updated = _withRecord(state, corrected);
        }
      }
      return updated.copyWith(
          requests: state.requests
              .map((item) => item.id == id
                  ? item.decide(
                      approve
                          ? AttendanceRequestStatus.approved
                          : AttendanceRequestStatus.rejected,
                      actorId,
                      note.trim(),
                      AttendanceClock.now)
                  : item)
              .toList());
    }, adminOnly: true);
  }

  bool canCancel(AttendanceRequest request) =>
      request.status == AttendanceRequestStatus.pending ||
      (request.status == AttendanceRequestStatus.approved &&
          [AttendanceRequestKind.leave, AttendanceRequestKind.offDaySwap]
              .contains(request.kind) &&
          request.day.compareTo(AttendanceClock.key(AttendanceClock.today)) >
              0 &&
          request.endDay.compareTo(AttendanceClock.key(AttendanceClock.today)) >
              0);

  Future<void> cancelRequest(String id, {required String actorId}) {
    final request = requestById(id);
    if (request == null) {
      return Future.error(const FormatException('Request not found.'));
    }
    return _commit(actorId, request.employeeId, request.day,
        '${request.kind.label} cancelled', (state) {
      final current = requestById(id)!;
      if (!canCancel(current)) {
        throw const FormatException('This request can no longer be cancelled.');
      }
      return state.copyWith(
          requests: state.requests
              .map((item) => item.id == id
                  ? item.decide(AttendanceRequestStatus.cancelled, actorId,
                      'Cancelled', AttendanceClock.now)
                  : item)
              .toList());
    });
  }

  Future<void> revokeOvertime(String id,
      {required String actorId, required String note}) {
    final request = requestById(id);
    if (request == null) {
      return Future.error(const FormatException('Request not found.'));
    }
    return _commit(
        actorId, request.employeeId, request.day, 'Overtime approval revoked',
        (state) {
      final current = requestById(id)!;
      if (current.kind != AttendanceRequestKind.overtime ||
          current.status != AttendanceRequestStatus.approved) {
        throw const FormatException('Only approved overtime can be revoked.');
      }
      if (note.trim().length < 5) {
        throw const FormatException(
            'Provide a reason for revoking this approval.');
      }
      return state.copyWith(
          requests: state.requests
              .map((item) => item.id == id
                  ? item.decide(AttendanceRequestStatus.cancelled, actorId,
                      note.trim(), AttendanceClock.now)
                  : item)
              .toList());
    }, adminOnly: true);
  }

  void _ensureOvertimeFits(AttendanceRecord next) {
    final approved = _approved(next.employeeId, AttendanceRequestKind.overtime)
        .where((request) => request.day == next.day)
        .fold(0, (sum, request) => sum + request.overtimeMinutes);
    final target =
        (next.wasWorkingDay || swappedWork(next.employeeId, next.day)) &&
                !swappedOff(next.employeeId, next.day)
            ? (next.requiredMinutes *
                    (1 - leaveUnits(next.employeeId, next.day) / 2))
                .round()
            : 0;
    if (approved >
        math.max(0, next.workedSeconds(AttendanceClock.now) ~/ 60 - target)) {
      throw const FormatException(
          'This change would conflict with approved overtime.');
    }
  }

  Future<void> setAttendance(
          {required String employeeId,
          required String day,
          required String actorId,
          required String note,
          DateTime? checkIn,
          DateTime? checkOut}) =>
      _commit(actorId, employeeId, day, 'Attendance updated by administrator',
          (state) {
        if (note.trim().length < 5) {
          throw const FormatException(
              'Provide a reason for this attendance change.');
        }
        if (day.compareTo(AttendanceClock.key(AttendanceClock.today)) > 0) {
          throw const FormatException('Future attendance cannot be marked.');
        }
        _validateEmploymentDate(employeeId, day);
        if (day.compareTo(policy.trackingStart) < 0) {
          throw const FormatException(
              'Choose a date after attendance tracking began.');
        }
        if (leaveUnits(employeeId, day) == 2) {
          throw const FormatException('This date has approved full-day leave.');
        }
        final original = recordFor(employeeId, day);
        final offset = original?.offsetMinutes ?? AttendanceClock.offsetMinutes;
        if (checkIn != null || checkOut != null) {
          if (checkIn == null || checkOut == null) {
            throw const FormatException('Provide both check-in and check-out.');
          }
          _validateTimes(day, checkIn, checkOut, offset);
          _validateOverlap(employeeId, day, checkIn, checkOut);
        } else if (!isWorkingDay(employeeId, day)) {
          throw const FormatException(
              'Absence cannot be marked on an off day or holiday.');
        }
        final record = _newRecord(employeeId, day,
            checkIn: checkIn,
            checkOut: checkOut,
            original: original,
            note: note.trim(),
            corrected: true,
            revision: (original?.revision ?? 0) + 1);
        _ensureOvertimeFits(record);
        return _withRecord(state, record);
      }, adminOnly: true);

  Future<void> updatePolicy(AttendancePolicy next, {required String actorId}) =>
      _commit(actorId, '', AttendanceClock.key(AttendanceClock.today),
          'Attendance policy updated', (state) {
        if (next.shiftMinutes == 0 ||
            next.requiredMinutes < 1 ||
            next.requiredMinutes > next.shiftMinutes ||
            next.graceMinutes < 0 ||
            next.graceMinutes > 180 ||
            next.paidBreakMinutes < 0 ||
            next.paidBreakMinutes > next.shiftMinutes ||
            next.offWeekdays.length > 6 ||
            next.correctionWindowDays < 1 ||
            next.correctionWindowDays > 365 ||
            next.trackingStart
                    .compareTo(AttendanceClock.key(AttendanceClock.today)) >
                0) {
          throw const FormatException(
              'Check shift hours, target hours, grace, break allowance, weekly off days, and request window.');
        }
        if (next.leaveTypes
                    .map((type) => type.name.trim().toLowerCase())
                    .toSet()
                    .length !=
                next.leaveTypes.length ||
            next.leaveTypes.any((type) =>
                type.name.trim().isEmpty ||
                (type.annualDays != null && type.annualDays! < 0))) {
          throw const FormatException(
              'Leave types must have unique names and a valid annual allowance.');
        }
        return state.copyWith(policy: next);
      }, adminOnly: true);
}
