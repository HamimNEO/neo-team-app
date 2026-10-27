import '../../../core/notifiers/frame_safe_notifier.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../settings/data/system_settings_store.dart';
import '../../team/data/employee_store.dart';
import '../../team/domain/models/employee.dart';
import '../domain/models/attendance_models.dart';
import 'attendance_api.dart';
import 'attendance_policy_mapper.dart';
import 'attendance_context.dart';
import 'attendance_clock.dart';

/// Attendance store with local fast-load and live backend synchronization.
class AttendanceStore extends FrameSafeNotifier {
  AttendanceStore._() {
    _accountToken = AuthSession.instance.accessToken;
    AuthSession.instance.addListener(() {
      if (_accountToken == AuthSession.instance.accessToken) return;
      _accountToken = AuthSession.instance.accessToken;
      _loading = null;
      loadError = null;
      _state = AttendanceState(policy: _state.policy);
      remoteMetrics = null;
      remoteCheckedInCount = remoteRequestsCount = null;
      notifyListeners();
    });
  }

  String? _accountToken;

  static final instance = AttendanceStore._();

  String get _key =>
      'nec_attendance_api_v2_${AuthSession.instance.user?.id ?? 'signedout'}';
  late AttendanceState _state = AttendanceState(
      policy: AttendancePolicy(
          trackingStart: AttendanceClock.key(AttendanceClock.today)));
  Future<void>? _loading;
  Future<void> _pending = Future.value();
  String? loadError;

  final AttendanceApi _api = AttendanceApi(ApiClient(
    baseUrl: () => AppConfig.apiBaseUrl,
    accessToken: () => AuthSession.instance.accessToken,
    onUnauthorized: AuthSession.instance.invalidate,
  ));

  AttendanceApi get api => _api;

  int? remoteCheckedInCount;
  int? remoteRequestsCount;
  Map<String, dynamic>? remoteMetrics;

  static bool _matchesEmployee(String idA, String idB) {
    if (idA == idB) return true;
    final a = idA.replaceFirst('api_emp_', '').trim();
    final b = idB.replaceFirst('api_emp_', '').trim();
    return a.isNotEmpty && a == b;
  }

  AttendanceState get state => _state;

  AttendancePolicy get policy => _state.policy;

  bool isAdministrator(String id) {
    return DemoSession.instance.isAdmin &&
        id == DemoSession.instance.employeeId;
  }

  String? get administratorId =>
      DemoSession.instance.isAdmin ? DemoSession.instance.employeeId : null;

  Future<void> load({bool forceRemote = false}) async {
    if (_loading == null || forceRemote) {
      _loading = _load();
    }
    await _loading;
    await syncRemote();
  }

  Future<void> _load() async {
    final accountToken = _accountToken;
    try {
      await SystemSettingsStore.instance.load();
      final prefs = await SharedPreferences.getInstance();
      if (accountToken != _accountToken) return;
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

  Future<void> syncRemote({String? day, String? month}) async {
    final token =
        AuthSession.instance.accessToken ?? DemoSession.instance.accessToken;
    if (token == null || !DemoSession.instance.signedIn) return;
    final targetDay = day ?? AttendanceClock.key(AttendanceClock.today);
    final storageKey = _key;

    try {
      if (DemoSession.instance.isAdmin) {
        try {
          final overview =
              await _api.getAdminOverview(date: targetDay, token: token);
          if (token != AuthSession.instance.accessToken) return;
          _state = _state.copyWith(
              policy: attendancePolicyFromApi(overview, policy));
          if (overview['metrics'] is Map) {
            remoteMetrics =
                Map<String, dynamic>.from(overview['metrics'] as Map);
            remoteCheckedInCount =
                (remoteMetrics!['attended_today'] as num?)?.toInt() ??
                    (remoteMetrics!['working_now'] as num?)?.toInt();
            remoteRequestsCount =
                (remoteMetrics!['pending_requests'] as num?)?.toInt();
          }
        } catch (_) {}

        final staffRes =
            await _api.getAdminStaff(date: targetDay, token: token);
        if (token != AuthSession.instance.accessToken) return;
        final rawData = staffRes['data'];
        if (rawData is List) {
          final updatedRecords = List<AttendanceRecord>.from(_state.records);
          for (final item in rawData) {
            if (item is Map) {
              final rawId = item['id'];
              if (rawId == null) continue;
              final empId = 'api_emp_$rawId';
              final att = item['attendance'];
              if (att is Map && att['check_in_at'] != null) {
                final serverStatus = att['status']?.toString().toLowerCase();
                final checkInDt =
                    AttendanceClock.parseServerTimestamp(att['check_in_at']);
                if (checkInDt != null) {
                  final checkOutDt =
                      AttendanceClock.parseServerTimestamp(att['check_out_at']);
                  final breakStartDt = AttendanceClock.parseServerTimestamp(
                      att['break_started_at']);
                  final breakEndDt = AttendanceClock.parseServerTimestamp(
                      att['break_ended_at']);

                  final existing = updatedRecords
                      .where((r) =>
                          _matchesEmployee(r.employeeId, empId) &&
                          r.day == targetDay)
                      .firstOrNull;

                  final breaks = _remoteBreaks(
                      existing, serverStatus, breakStartDt, breakEndDt);

                  updatedRecords.removeWhere((r) =>
                      _matchesEmployee(r.employeeId, empId) &&
                      r.day == targetDay);

                  final offset = AttendanceClock.offsetMinutes;
                  final start = AttendanceClock.instant(
                      targetDay, policy.startMinutes, offset);

                  final effectiveAdminOut = checkOutDt ??
                      (serverStatus == 'checked_out'
                          ? (existing?.checkOut ?? AttendanceClock.now)
                          : existing?.checkOut);

                  updatedRecords.add(AttendanceRecord(
                    metadata: Map<String, dynamic>.from(att),
                    serverStatus: serverStatus,
                    reportedWorkedMinutes: effectiveAdminOut != null
                        ? (att['worked_minutes'] as num?)?.toInt()
                        : null,
                    reportedBreakMinutes: effectiveAdminOut != null
                        ? (att['break_minutes'] as num?)?.toInt()
                        : null,
                    employeeId: empId,
                    day: targetDay,
                    checkIn: checkInDt,
                    checkOut: effectiveAdminOut,
                    breaks: breaks,
                    offsetMinutes: offset,
                    requiredMinutes: (att['target_minutes'] as num?)?.toInt() ??
                        policy.requiredMinutes,
                    expectedStart: start,
                    shiftMinutes: policy.shiftMinutes,
                    graceMinutes: policy.graceMinutes,
                    paidBreakMinutes: policy.paidBreakMinutes,
                    wasWorkingDay: true,
                  ));
                }
              }
            }
          }
          _state = _state.copyWith(records: updatedRecords);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(storageKey, jsonEncode(_state.toJson()));
          notifyListeners();
        }

        try {
          final pendingRes = await _api.allRequests(admin: true, token: token);
          if (token != AuthSession.instance.accessToken) return;
          final rawReqs = pendingRes['data'];
          if (rawReqs is List) {
            final updatedRequests =
                List<AttendanceRequest>.from(_state.requests);
            for (final r in rawReqs) {
              if (r is Map) {
                final parsed =
                    _parseRemoteRequest(Map<String, dynamic>.from(r));
                if (parsed != null) {
                  updatedRequests.removeWhere((existing) =>
                      existing.id == parsed.id ||
                      (existing.kind == parsed.kind &&
                          existing.employeeId == parsed.employeeId &&
                          existing.day == parsed.day));
                  updatedRequests.add(parsed);
                }
              }
            }
            _state = _state.copyWith(requests: updatedRequests);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(storageKey, jsonEncode(_state.toJson()));
            notifyListeners();
          }
        } catch (_) {}
      } else {
        final targetMonth = month ?? targetDay.substring(0, 7);
        final myRes = await _api.getMyAttendance(
            month: month == null ? null : targetMonth, token: token);
        if (token != AuthSession.instance.accessToken) return;
        final today = myRes['today'];
        if (today is Map) {
          final serverStatus = today['status']?.toString().toLowerCase();
          final checkInDt =
              AttendanceClock.parseServerTimestamp(today['check_in_at']);
          final checkOutDt =
              AttendanceClock.parseServerTimestamp(today['check_out_at']);
          final breakStartDt =
              AttendanceClock.parseServerTimestamp(today['break_started_at']);
          final breakEndDt =
              AttendanceClock.parseServerTimestamp(today['break_ended_at']);
          final myEmpId = DemoSession.instance.employeeId;
          final updatedRecords = List<AttendanceRecord>.from(_state.records);
          final existing = updatedRecords
              .where((r) =>
                  _matchesEmployee(r.employeeId, myEmpId) && r.day == targetDay)
              .firstOrNull;

          final effectiveCheckIn = checkInDt ??
              (serverStatus == 'not_checked_in' ? null : existing?.checkIn);
          if (effectiveCheckIn != null) {
            final breaks =
                _remoteBreaks(existing, serverStatus, breakStartDt, breakEndDt);

            updatedRecords.removeWhere((r) =>
                _matchesEmployee(r.employeeId, myEmpId) && r.day == targetDay);

            final offset = AttendanceClock.offsetMinutes;
            final start =
                AttendanceClock.instant(targetDay, policy.startMinutes, offset);

            final effectiveCheckOut = checkOutDt ??
                (serverStatus == 'checked_out'
                    ? (existing?.checkOut ?? AttendanceClock.now)
                    : (checkInDt != null ? existing?.checkOut : null));

            updatedRecords.add(AttendanceRecord(
              metadata: Map<String, dynamic>.from(today),
              serverStatus: serverStatus,
              reportedWorkedMinutes: effectiveCheckOut != null
                  ? (today['worked_minutes'] as num?)?.toInt()
                  : null,
              reportedBreakMinutes: effectiveCheckOut != null
                  ? (today['break_minutes'] as num?)?.toInt()
                  : null,
              employeeId: myEmpId,
              day: targetDay,
              checkIn: effectiveCheckIn,
              checkOut: effectiveCheckOut,
              breaks: breaks,
              offsetMinutes: offset,
              requiredMinutes: (today['target_minutes'] as num?)?.toInt() ??
                  policy.requiredMinutes,
              expectedStart: start,
              shiftMinutes: policy.shiftMinutes,
              graceMinutes: policy.graceMinutes,
              paidBreakMinutes: policy.paidBreakMinutes,
              wasWorkingDay: true,
            ));
            _state = _state.copyWith(records: updatedRecords);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(storageKey, jsonEncode(_state.toJson()));
            notifyListeners();
          } else if (serverStatus == 'not_checked_in') {
            updatedRecords.removeWhere((r) =>
                _matchesEmployee(r.employeeId, myEmpId) && r.day == targetDay);
            _state = _state.copyWith(records: updatedRecords);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(storageKey, jsonEncode(_state.toJson()));
            notifyListeners();
          }
        }

        final history = myRes['month']?['daily_history'];
        if (history is List) {
          final updatedRecords = List<AttendanceRecord>.from(_state.records);
          var historyChanged = false;
          final myEmpId = DemoSession.instance.employeeId;
          final offset = AttendanceClock.offsetMinutes;

          for (final dayItem in history) {
            if (dayItem is Map) {
              final hDate = dayItem['date']?.toString();
              if (hDate == null || hDate == targetDay) continue;
              final hIn =
                  AttendanceClock.parseServerTimestamp(dayItem['check_in_at']);
              if (hIn == null) continue;
              final hOut =
                  AttendanceClock.parseServerTimestamp(dayItem['check_out_at']);
              final hStart =
                  AttendanceClock.instant(hDate, policy.startMinutes, offset);

              updatedRecords.removeWhere((r) =>
                  _matchesEmployee(r.employeeId, myEmpId) && r.day == hDate);
              updatedRecords.add(AttendanceRecord(
                reportedWorkedMinutes:
                    (dayItem['worked_minutes'] as num?)?.toInt(),
                reportedBreakMinutes:
                    (dayItem['break_minutes'] as num?)?.toInt(),
                employeeId: myEmpId,
                day: hDate,
                checkIn: hIn,
                checkOut: hOut,
                offsetMinutes: offset,
                requiredMinutes: (dayItem['target_minutes'] as num?)?.toInt() ??
                    policy.requiredMinutes,
                expectedStart: hStart,
                shiftMinutes: policy.shiftMinutes,
                graceMinutes: policy.graceMinutes,
                paidBreakMinutes: policy.paidBreakMinutes,
                wasWorkingDay: true,
              ));
              historyChanged = true;
            }
          }
          if (historyChanged) {
            _state = _state.copyWith(records: updatedRecords);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(storageKey, jsonEncode(_state.toJson()));
            notifyListeners();
          }
        }

        try {
          final myReqRes = await _api.allRequests(token: token);
          final rawReqs = myReqRes['data'];
          if (rawReqs is List) {
            final updatedRequests =
                List<AttendanceRequest>.from(_state.requests);
            for (final r in rawReqs) {
              if (r is Map) {
                final parsed = _parseRemoteRequest(Map<String, dynamic>.from(r),
                    defaultEmpId: DemoSession.instance.employeeId);
                if (parsed != null) {
                  updatedRequests.removeWhere((existing) =>
                      existing.id == parsed.id ||
                      (existing.kind == parsed.kind &&
                          existing.employeeId == parsed.employeeId &&
                          existing.day == parsed.day));
                  updatedRequests.add(parsed);
                }
              }
            }
            _state = _state.copyWith(requests: updatedRequests);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(storageKey, jsonEncode(_state.toJson()));
            notifyListeners();
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Failed to sync remote attendance: $e');
    }
  }

  List<AttendanceBreak> _remoteBreaks(AttendanceRecord? existing,
      String? status, DateTime? start, DateTime? end) {
    final closed = existing?.breaks.where((b) => b.end != null).toList() ??
        <AttendanceBreak>[];
    if (status == 'on_break' && start != null) {
      return [
        ...closed.where((b) => !b.end!.isAfter(start)),
        AttendanceBreak(start)
      ];
    }
    if (start != null && end != null && !closed.any((b) => b.start == start)) {
      closed.add(AttendanceBreak(start, end));
    }
    return closed;
  }

  Future<void> loadMonth(String employeeId, DateTime month) async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    if (!DemoSession.instance.isAdmin) {
      if (employeeId == DemoSession.instance.employeeId) {
        await syncRemote(month: key);
      }
      return;
    }
    final response = await _api.getAdminReports(month: key, token: token);
    if (token != AuthSession.instance.accessToken) return;
    final rows = response['employees'];
    if (rows is! List) return;
    final records = List<AttendanceRecord>.of(_state.records);
    for (final row in rows.whereType<Map>()) {
      final employee = row['employee'];
      if (employee is! Map ||
          !_matchesEmployee(employeeId, '${employee['id']}')) {
        continue;
      }
      final summary = row['summary'];
      final history = summary is Map ? summary['daily_history'] : null;
      if (history is! List) continue;
      records.removeWhere((r) =>
          _matchesEmployee(r.employeeId, employeeId) && r.day.startsWith(key));
      for (final day in history.whereType<Map>()) {
        final date = day['date']?.toString();
        final checkIn =
            AttendanceClock.parseServerTimestamp(day['check_in_at']);
        if (date == null || checkIn == null) continue;
        records.add(AttendanceRecord(
            employeeId: employeeId,
            day: date,
            checkIn: checkIn,
            checkOut: AttendanceClock.parseServerTimestamp(day['check_out_at']),
            offsetMinutes: AttendanceClock.offsetMinutes,
            requiredMinutes: (day['target_minutes'] as num?)?.toInt() ??
                policy.requiredMinutes,
            expectedStart: AttendanceClock.instant(date, policy.startMinutes),
            shiftMinutes: policy.shiftMinutes,
            graceMinutes: policy.graceMinutes,
            paidBreakMinutes: policy.paidBreakMinutes,
            reportedWorkedMinutes: (day['worked_minutes'] as num?)?.toInt(),
            reportedBreakMinutes: (day['break_minutes'] as num?)?.toInt()));
      }
    }
    _state = _state.copyWith(records: records);
    notifyListeners();
  }

  DateTime? _timeOnDay(String day, String timeStr, int offset) {
    final parts = timeStr.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final min = int.tryParse(parts[1]);
    if (hour == null || min == null) return null;
    final totalMin = hour * 60 + min;
    return AttendanceClock.instant(day, totalMin, offset);
  }

  AttendanceRequest? _parseRemoteRequest(Map<String, dynamic> item,
      {String? defaultEmpId}) {
    final rawId = item['id']?.toString();
    if (rawId == null) return null;
    final typeStr = item['type']?.toString().toLowerCase();
    final kind = switch (typeStr) {
      'leave' => AttendanceRequestKind.leave,
      'attendance_fix' => AttendanceRequestKind.correction,
      'off_day_swap' => AttendanceRequestKind.offDaySwap,
      'overtime' => AttendanceRequestKind.overtime,
      _ => null,
    };
    if (kind == null) return null;

    final statusStr = item['status']?.toString().toLowerCase();
    final status = switch (statusStr) {
      'approved' => AttendanceRequestStatus.approved,
      'rejected' => AttendanceRequestStatus.rejected,
      'cancelled' => AttendanceRequestStatus.cancelled,
      'revoked' => AttendanceRequestStatus.revoked,
      _ => AttendanceRequestStatus.pending,
    };

    String empId = defaultEmpId ?? '';
    final empMap = item['employee'];
    if (empMap is Map) {
      final code = empMap['employee_code']?.toString();
      final name = empMap['name']?.toString();
      final matched = EmployeeStore.instance.staffEmployees
          .where((e) =>
              (code != null &&
                  e.displayCode.toLowerCase() == code.toLowerCase()) ||
              (name != null && e.name.toLowerCase() == name.toLowerCase()))
          .firstOrNull;
      if (matched != null) {
        empId = matched.id;
      }
    }
    if (empId.isEmpty) {
      empId = defaultEmpId ?? DemoSession.instance.employeeId;
    }

    final startDate = item['start_date']?.toString() ??
        AttendanceClock.key(AttendanceClock.today);
    final endDate = item['end_date']?.toString() ?? startDate;
    final reason = item['reason']?.toString() ?? '';
    final details = item['details'] is Map
        ? Map<String, dynamic>.from(item['details'] as Map)
        : <String, dynamic>{};
    final halfDay = details['half_day'] == true;
    final leaveType = item['leave_type']?.toString();
    final otMinutes = (details['minutes'] as num?)?.toInt() ?? 0;
    final offset = AttendanceClock.offsetMinutes;

    DateTime? proposedIn;
    DateTime? proposedOut;
    if (details['correct_check_in'] != null) {
      proposedIn =
          _timeOnDay(startDate, details['correct_check_in'].toString(), offset);
    }
    if (details['correct_check_out'] != null) {
      final nextDay = details['check_out_next_day'] == true;
      final outDate = nextDay
          ? AttendanceClock.key(
              AttendanceClock.date(startDate).add(const Duration(days: 1)))
          : startDate;
      proposedOut =
          _timeOnDay(outDate, details['correct_check_out'].toString(), offset);
    }

    final createdAt =
        AttendanceClock.parseServerTimestamp(item['created_at']) ??
            AttendanceClock.now;

    return AttendanceRequest(
      id: 'req_api_$rawId',
      employeeId: empId,
      kind: kind,
      status: status,
      day: startDate,
      endDay: kind == AttendanceRequestKind.offDaySwap
          ? (details['replacement_off_date']?.toString() ?? endDate)
          : endDate,
      reason: reason,
      createdAt: createdAt,
      offsetMinutes: offset,
      typeId: leaveType ?? '',
      typeName: leaveType != null && leaveType.isNotEmpty
          ? '${leaveType[0].toUpperCase()}${leaveType.substring(1)} Leave'
          : '',
      halfDayPart: halfDay ? 'First half' : '',
      leaveUnits: kind == AttendanceRequestKind.leave
          ? {
              for (var d = AttendanceClock.date(startDate);
                  !d.isAfter(AttendanceClock.date(endDate));
                  d = d.add(const Duration(days: 1)))
                AttendanceClock.key(d): halfDay ? 1 : 2
            }
          : const {},
      proposedIn: proposedIn,
      proposedOut: proposedOut,
      overtimeMinutes: otMinutes,
      decisionNote: item['review_note']?.toString() ?? '',
      reviewedAt: AttendanceClock.parseServerTimestamp(item['reviewed_at']),
    );
  }

  Employee? _employee(String id) {
    return EmployeeStore.instance.byId(id);
  }

  void _authorize(String actorId, String employeeId, {bool adminOnly = false}) {
    if (!DemoSession.instance.signedIn ||
        actorId != DemoSession.instance.employeeId) {
      throw const FormatException(
          'Use your signed-in account for this action.');
    }
    if (DemoSession.instance.isAdmin && actorId == employeeId && !adminOnly) {
      throw const FormatException(
          'Use attendance management to manage staff attendance.');
    }
    if (!DemoSession.instance.isAdmin &&
        !StaffAccessStore.instance.allows(StaffPermission.attendance)) {
      throw const FormatException(
          'Attendance access is disabled by your administrator.');
    }
    final actor = _employee(actorId);
    if (actor != null &&
        actor.status != 'Active' &&
        !DemoSession.instance.isAdmin) {
      throw const FormatException('An active account is required.');
    }
    if ((adminOnly || actorId != employeeId) && !isAdministrator(actorId)) {
      throw const FormatException('Administrator access is required.');
    }
  }

  Future<void> _commit(String actorId, String employeeId, String day,
      String title, AttendanceState Function(AttendanceState) transform,
      {bool adminOnly = false, Future<void> Function()? beforeSave}) async {
    final accountToken = _accountToken;
    final storageKey = _key;
    await load();
    final write = _pending.then((_) async {
      if (accountToken != _accountToken) {
        throw const FormatException('Your account changed.');
      }
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
      await beforeSave?.call();
      if (accountToken != _accountToken) {
        throw const FormatException('Your account changed.');
      }
      final prefs = await SharedPreferences.getInstance();
      if (accountToken != _accountToken) {
        throw const FormatException('Your account changed.');
      }
      if (!await prefs.setString(storageKey, jsonEncode(updated.toJson()))) {
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
      .where((record) =>
          _matchesEmployee(record.employeeId, employeeId) && record.day == day)
      .firstOrNull;

  AttendanceRecord? activeRecord(String employeeId) {
    final today = checkInDay;
    final todayOpen = _state.records
        .where((record) =>
            _matchesEmployee(record.employeeId, employeeId) &&
            record.day == today &&
            record.open)
        .firstOrNull;
    if (todayOpen != null) return todayOpen;

    if (AuthSession.instance.accessToken != null) {
      return null;
    }

    return _state.records
        .where((record) =>
            _matchesEmployee(record.employeeId, employeeId) && record.open)
        .firstOrNull;
  }

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

  DateTime _joined(Employee? employee) {
    if (employee == null) {
      return DateTime.utc(1900);
    }
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
    final emp = _employee(employeeId);
    if (day.compareTo(policy.trackingStart) < 0 ||
        (emp != null && AttendanceClock.date(day).isBefore(_joined(emp)))) {
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

  Future<void> checkIn(String employeeId) async {
    final liveToken = AuthSession.instance.accessToken;
    if (liveToken != null && !DemoSession.instance.isAdmin) {
      if (employeeId != DemoSession.instance.employeeId) {
        throw const FormatException('You can only manage your own attendance.');
      }
      await _api.checkIn(
          token: liveToken, context: await AttendanceContext.collect());
      if (liveToken != AuthSession.instance.accessToken) return;
      await syncRemote();
      return;
    }

    await _commit(employeeId, employeeId, checkInDay, 'Checked in', (state) {
      final day = checkInDay;
      final emp = _employee(employeeId);
      if (day.compareTo(policy.trackingStart) < 0 ||
          (emp != null && AttendanceClock.date(day).isBefore(_joined(emp)))) {
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
  }

  Future<void> checkOut(String employeeId,
      {String? summary, String? workNotes}) async {
    final liveToken = AuthSession.instance.accessToken;
    if (liveToken != null && !DemoSession.instance.isAdmin) {
      if (employeeId != DemoSession.instance.employeeId) {
        throw const FormatException('You can only manage your own attendance.');
      }
      final outRes = await _api.checkOut(
          token: liveToken,
          context: await AttendanceContext.collect(),
          summary: summary,
          workNotes: workNotes);
      if (liveToken != AuthSession.instance.accessToken) return;
      final now = AttendanceClock.now;
      final existing =
          activeRecord(employeeId) ?? recordFor(employeeId, checkInDay);
      if (existing != null) {
        DateTime? serverOut;
        final data = outRes['data'] is Map ? outRes['data'] as Map : outRes;
        if (data['check_out_at'] != null) {
          serverOut = AttendanceClock.parseServerTimestamp(data['check_out_at']);
        }
        final updatedBreaks = existing.breaks
            .map((item) => AttendanceBreak(item.start, item.end ?? now))
            .toList();
        final updatedRecord = existing.copyWith(
          checkOut: serverOut ?? now,
          serverStatus: 'checked_out',
          breaks: updatedBreaks,
        );
        final updatedRecords = List<AttendanceRecord>.from(_state.records)
          ..removeWhere((r) =>
              _matchesEmployee(r.employeeId, employeeId) &&
              r.day == existing.day)
          ..add(updatedRecord);
        _state = _state.copyWith(records: updatedRecords);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, jsonEncode(_state.toJson()));
        notifyListeners();
      }
      await syncRemote();
      return;
    }

    await _commit(
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
  }

  Future<void> toggleBreak(String employeeId) async {
    final liveToken = AuthSession.instance.accessToken;
    if (liveToken != null && !DemoSession.instance.isAdmin) {
      if (employeeId != DemoSession.instance.employeeId) {
        throw const FormatException('You can only manage your own attendance.');
      }
      if (activeRecord(employeeId)?.onBreak == true) {
        await _api.endBreak(token: liveToken);
      } else {
        await _api.startBreak(token: liveToken);
      }
      if (liveToken != AuthSession.instance.accessToken) return;
      await syncRemote();
      return;
    }

    await _commit(
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
  }

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
    final emp = _employee(request.employeeId);
    if (emp != null && emp.status != 'Active') {
      throw const FormatException('This employee is inactive.');
    }
    for (final entry in request.leaveUnits.entries) {
      if (emp != null &&
          AttendanceClock.date(entry.key).isBefore(_joined(emp))) {
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
    final emp = _employee(employeeId);
    if (emp != null && AttendanceClock.date(day).isBefore(_joined(emp))) {
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
      int overtimeMinutes = 0}) async {
    final token = AuthSession.instance.accessToken;
    if (token != null) {
      _authorize(actorId ?? employeeId, employeeId);
      if (DemoSession.instance.isAdmin) {
        throw const FormatException(
            'Staff submit attendance requests; administrators review them.');
      }
      if (reason.trim().length < 5) {
        throw const FormatException(
            'Provide a reason of at least 5 characters.');
      }
      String hhmm(DateTime value) {
        final wall = AttendanceClock.wallTime(value);
        return '${wall.hour.toString().padLeft(2, '0')}:${wall.minute.toString().padLeft(2, '0')}';
      }

      final body = <String, dynamic>{
        'type': switch (kind) {
          AttendanceRequestKind.leave => 'leave',
          AttendanceRequestKind.correction => 'attendance_fix',
          AttendanceRequestKind.offDaySwap => 'off_day_swap',
          AttendanceRequestKind.overtime => 'overtime'
        },
        'start_date': day,
        'reason': reason.trim(),
        if (kind == AttendanceRequestKind.leave) ...{
          'leave_type': typeId,
          'end_date': endDay ?? day,
          'half_day': halfDay
        },
        if (kind == AttendanceRequestKind.correction &&
            proposedIn != null &&
            proposedOut != null)
          'details': {
            'correct_check_in': hhmm(proposedIn),
            'correct_check_out': hhmm(proposedOut),
            'check_out_next_day':
                AttendanceClock.key(AttendanceClock.wallTime(proposedOut)) !=
                    day
          },
        if (kind == AttendanceRequestKind.offDaySwap)
          'details': {'replacement_off_date': endDay ?? day},
        if (kind == AttendanceRequestKind.overtime)
          'details': {'minutes': overtimeMinutes}
      };
      await _api.submitRequest(body, token: token);
      if (token == AuthSession.instance.accessToken) await syncRemote();
      return;
    }
    await _commit(
        actorId ?? employeeId, employeeId, day, '${kind.label} requested',
        (state) {
      if (DemoSession.instance.isAdmin ||
          !EmployeeStore.instance.isStaffEmployee(employeeId)) {
        throw const FormatException(
            'Attendance requests are submitted by staff. Administrators review them in attendance management.');
      }
      if (reason.trim().length < 5) {
        throw const FormatException(
            'Please provide a reason of at least 5 characters.');
      }
      final emp = _employee(employeeId);
      if (emp != null && emp.status != 'Active') {
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
  }

  Future<void> reviewRequest(String id,
      {required String actorId,
      required bool approve,
      required String note}) async {
    final liveToken = AuthSession.instance.accessToken;
    if (liveToken != null && id.startsWith('req_api_')) {
      if (!DemoSession.instance.isAdmin) {
        throw const FormatException('Administrator access is required.');
      }
      await _api.reviewAdminRequest(
          id.substring(8),
          {
            'status': approve ? 'approved' : 'rejected',
            'review_note': note.trim()
          },
          token: liveToken);
      if (liveToken == AuthSession.instance.accessToken) await syncRemote();
      return;
    }
    final initial = requestById(id);
    if (initial == null) {
      throw const FormatException('Request not found.');
    }
    await _commit(actorId, initial.employeeId, initial.day,
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

    final token =
        AuthSession.instance.accessToken ?? DemoSession.instance.accessToken;
    if (token != null &&
        DemoSession.instance.signedIn &&
        DemoSession.instance.isAdmin) {
      final serverId = id.startsWith('req_api_') ? id.substring(8) : id;
      unawaited(_api
          .reviewAdminRequest(
              serverId,
              {
                'status': approve ? 'approved' : 'rejected',
                'review_note': note.trim().isEmpty
                    ? (approve ? 'Approved' : 'Rejected')
                    : note.trim(),
              },
              token: token)
          .then((_) {
        syncRemote();
      }).catchError((e) {
        debugPrint('Backend reviewAdminRequest: $e');
      }));
    }
  }

  bool canCancel(AttendanceRequest request) =>
      request.status == AttendanceRequestStatus.pending ||
      (!AuthSession.instance.signedIn &&
          request.status == AttendanceRequestStatus.approved &&
          [AttendanceRequestKind.leave, AttendanceRequestKind.offDaySwap]
              .contains(request.kind) &&
          request.day.compareTo(AttendanceClock.key(AttendanceClock.today)) >
              0 &&
          request.endDay.compareTo(AttendanceClock.key(AttendanceClock.today)) >
              0);

  Future<void> _applyRequestDecision(Map<String, dynamic> response, String id,
      String token, String actor, String note) async {
    if (token != AuthSession.instance.accessToken) return;
    final raw = response['request'];
    final status = raw is Map ? raw['status']?.toString() : null;
    final parsed = AttendanceRequestStatus.values
        .where((v) => v.name == status)
        .firstOrNull;
    if (parsed != null) {
      _state = _state.copyWith(
          requests: _state.requests
              .map((r) => r.id == id
                  ? r.decide(parsed, actor, note, AttendanceClock.now)
                  : r)
              .toList());
      final key = _key, prefs = await SharedPreferences.getInstance();
      if (token != AuthSession.instance.accessToken) return;
      await prefs.setString(key, jsonEncode(_state.toJson()));
      notifyListeners();
    }
    await syncRemote();
  }

  Future<void> cancelRequest(String id, {required String actorId}) {
    if (AuthSession.instance.signedIn && id.startsWith('req_api_')) {
      final token = AuthSession.instance.accessToken!;
      final request = requestById(id);
      if (request == null ||
          request.employeeId != actorId ||
          request.status != AttendanceRequestStatus.pending) {
        return Future.error(const FormatException(
            'Only your pending requests can be cancelled.'));
      }
      return _api.cancelRequest(id.substring(8), token: token).then(
          (response) =>
              _applyRequestDecision(response, id, token, actorId, 'Cancelled'));
    }
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
    if (AuthSession.instance.signedIn && id.startsWith('req_api_')) {
      if (!AuthSession.instance.isAdmin || note.trim().length < 5) {
        return Future.error(const FormatException(
            'Administrator access and a reason are required.'));
      }
      final token = AuthSession.instance.accessToken!;
      return _api
          .revokeOvertime(id.substring(8), note.trim(), token: token)
          .then((response) =>
              _applyRequestDecision(response, id, token, actorId, note.trim()));
    }
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
      DateTime? checkOut}) async {
    final token = AuthSession.instance.accessToken;
    if (token != null) {
      _authorize(actorId, employeeId, adminOnly: true);
      String time(DateTime value) {
        final wall = AttendanceClock.wallTime(value);
        return '${wall.hour.toString().padLeft(2, '0')}:${wall.minute.toString().padLeft(2, '0')}';
      }

      await _api.manageEmployeeAttendance(
          employeeId.replaceFirst('api_emp_', ''),
          {
            'date': day,
            'record_type': checkIn == null ? 'absent' : 'recorded_attendance',
            if (checkIn != null) 'check_in': time(checkIn),
            if (checkOut != null) 'check_out': time(checkOut),
            'check_out_next_day': checkOut != null &&
                AttendanceClock.key(AttendanceClock.wallTime(checkOut)) != day,
            'reason': note.trim()
          },
          token: token);
      if (token == AuthSession.instance.accessToken) await syncRemote(day: day);
      return;
    }
    await _commit(
        actorId, employeeId, day, 'Attendance updated by administrator',
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
  }

  Future<void> loadPolicy() async {
    if (!DemoSession.instance.isAdmin || !AuthSession.instance.signedIn) return;
    final token = AuthSession.instance.accessToken!;
    final response = await _api.getAdminSettings(token: token);
    if (token != AuthSession.instance.accessToken) return;
    _state = _state.copyWith(policy: attendancePolicyFromApi(response, policy));
    notifyListeners();
  }

  Future<void> updatePolicy(AttendancePolicy next,
      {required String actorId}) async {
    try {
      await _commit(
          actorId,
          '',
          AttendanceClock.key(AttendanceClock.today),
          'Attendance policy updated',
          (state) {
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
          },
          adminOnly: true,
          beforeSave: () async {
            final token = AuthSession.instance.accessToken;
            if (token == null) return;
            await _api.updateAdminSettings(attendancePolicyToApi(next),
                token: token);
            final previous = List<AttendanceHoliday>.of(policy.holidays);
            for (final old in previous) {
              final replacement = next.holidays
                  .where((h) =>
                      h.id == old.id && old.id != null || h.day == old.day)
                  .firstOrNull;
              if (replacement == null) {
                if (old.id == null) {
                  throw const FormatException(
                      'Refresh attendance settings to obtain the holiday ID.');
                }
                await _api.deleteHoliday(old.id!, token: token);
              } else if (replacement.day != old.day ||
                  replacement.name != old.name) {
                if (old.id == null) {
                  throw const FormatException(
                      'Refresh attendance settings to obtain the holiday ID.');
                }
                await _api.updateHoliday(old.id!,
                    {'holiday_date': replacement.day, 'name': replacement.name},
                    token: token);
              }
            }
            for (final holiday in next.holidays) {
              if (!previous.any((old) =>
                  old.id != null && old.id == holiday.id ||
                  old.day == holiday.day)) {
                await _api.addHoliday(
                    {'holiday_date': holiday.day, 'name': holiday.name},
                    token: token);
              }
            }
            // Reload server IDs/status after the policy transaction completes.
          });
    } finally {
      if (AuthSession.instance.signedIn) {
        await syncRemote();
        await loadPolicy();
      }
    }
  }
}
