import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../attendance/data/attendance_clock.dart';
import '../../attendance/data/attendance_store.dart';
import '../../team/data/employee_store.dart';
import '../domain/models/lunch_preference.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';

/// Local lunch preferences for the app's existing demo workspaces.
class MealStore extends ChangeNotifier {
  MealStore._();

  static final instance = MealStore._();
  static const _key = 'nec_lunch_preferences_v1';
  List<LunchPreference> _changes = const [];
  Future<void>? _loading;
  Future<void> _pending = Future<void>.value();
  String? loadError;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      await AttendanceStore.instance.load();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        if (json['version'] != 1) {
          throw const FormatException('Unsupported lunch data.');
        }
        _changes = List.unmodifiable((json['changes'] as List).map((item) =>
            LunchPreference.fromJson(Map<String, dynamic>.from(item as Map))));
      }
    } catch (_) {
      loadError =
          'Lunch preferences could not be loaded. Restart the app before making changes.';
    }
  }

  LunchPreference? preferenceFor(String employeeId, String day) => _changes
      .where((change) => change.employeeId == employeeId && change.day == day)
      .lastOrNull;

  List<LunchPreference> historyFor(String? employeeId, String day) => _changes
      .where((change) =>
          (employeeId == null || change.employeeId == employeeId) &&
          change.day == day)
      .toList()
      .reversed
      .toList();

  LunchStatus statusFor(String employeeId, String day) {
    final employee = EmployeeStore.instance.byId(employeeId);
    if (employee == null || employee.status != 'Active') {
      return LunchStatus.inactive;
    }
    final attendance = AttendanceStore.instance;
    if (attendance.leaveUnits(employeeId, day) >= 2) {
      return LunchStatus.leave;
    }
    if (!attendance.isWorkingDay(employeeId, day) &&
        attendance.recordFor(employeeId, day)?.checkIn == null) {
      return LunchStatus.offDay;
    }
    return preferenceFor(employeeId, day)?.takeLunch == false
        ? LunchStatus.skipped
        : LunchStatus.receiving;
  }

  bool canChange(String day, {required bool administrator}) {
    final difference =
        day.compareTo(AttendanceClock.key(AttendanceClock.today));
    return administrator ? difference >= 0 : difference > 0;
  }

  Future<void> setLunch(
      {required String employeeId,
      required String day,
      required bool takeLunch,
      required String actorId}) async {
    await load();
    final write = _pending.then((_) async {
      if (loadError != null) {
        throw FormatException(loadError!);
      }
      if (AttendanceStore.instance.loadError != null) {
        throw FormatException(AttendanceStore.instance.loadError!);
      }
      final actor = EmployeeStore.instance.byId(actorId);
      final isAdmin = AttendanceStore.instance.isAdministrator(actorId);
      if (!DemoSession.instance.signedIn ||
          actorId != DemoSession.instance.employeeId ||
          !StaffAccessStore.instance.allows(StaffPermission.meals) ||
          (actor?.status != 'Active' && !isAdmin) ||
          (actorId != employeeId && !isAdmin)) {
        throw const FormatException(
            'You cannot change this employee’s lunch preference.');
      }
      final date = AttendanceClock.date(day);
      if (AttendanceClock.key(date) != day ||
          !canChange(day, administrator: isAdmin)) {
        throw const FormatException(
            'Staff can change upcoming lunches before that day begins. Contact admin for today’s lunch.');
      }
      if (!statusFor(employeeId, day).available) {
        throw const FormatException(
            'Lunch is unavailable on days off, approved full-day leave, or inactive accounts.');
      }
      if ((statusFor(employeeId, day) == LunchStatus.receiving) == takeLunch) {
        return;
      }
      final updated = [
        ..._changes,
        LunchPreference(
            employeeId: employeeId,
            day: day,
            takeLunch: takeLunch,
            actorId: actorId,
            updatedAt: AttendanceClock.now)
      ];
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
          _key,
          jsonEncode({
            'version': 1,
            'changes': updated.map((change) => change.toJson()).toList()
          }))) {
        throw const FormatException(
            'Lunch preference could not be saved. Please try again.');
      }
      _changes = List.unmodifiable(updated);
      notifyListeners();
    });
    _pending = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    await write;
  }
}
