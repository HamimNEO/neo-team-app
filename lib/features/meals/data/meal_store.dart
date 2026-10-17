import '../../../core/notifiers/frame_safe_notifier.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';
import '../../attendance/data/attendance_clock.dart';
import '../../attendance/data/attendance_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../team/data/employee_store.dart';
import '../domain/models/lunch_preference.dart';
import 'lunch_api.dart';

/// Lunch preferences with fast local caching and live backend synchronization.
class MealStore extends FrameSafeNotifier {
  MealStore._() {
    _accountToken = AuthSession.instance.accessToken;
    AuthSession.instance.addListener(() {
      if (_accountToken == AuthSession.instance.accessToken) return;
      _accountToken = AuthSession.instance.accessToken;
      _loading = null;
      loadError = null;
      _changes = const [];
      policy = {};
      monthlySummary = {};
      _monthlyKey = null;
      _monthError = null;
      remoteDayCounts.clear();
      remoteError = null;
      notifyListeners();
    });
  }

  String? _accountToken;

  static final instance = MealStore._();

  String get _key =>
      'nec_lunch_api_v2_${AuthSession.instance.user?.id ?? 'signedout'}';
  List<LunchPreference> _changes = const [];
  Future<void>? _loading;
  Future<void> _pending = Future<void>.value();
  String? loadError, remoteError;
  Map<String, dynamic> policy = {}, monthlySummary = {};
  String? _monthlyKey;
  String? _monthError;

  String? get monthlyError => _monthError;

  final LunchApi _lunchApi = LunchApi(ApiClient(
    baseUrl: () => AppConfig.apiBaseUrl,
    accessToken: () => AuthSession.instance.accessToken,
    onUnauthorized: AuthSession.instance.invalidate,
  ));

  LunchApi get api => _lunchApi;

  static bool _matchesEmployee(String idA, String idB) {
    if (idA == idB) return true;
    final a = idA.replaceFirst('api_emp_', '').trim();
    final b = idB.replaceFirst('api_emp_', '').trim();
    return a.isNotEmpty && a == b;
  }

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
      await AttendanceStore.instance.load();
      final prefs = await SharedPreferences.getInstance();
      if (accountToken != _accountToken) return;
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

  final Map<String, Map<String, int>> remoteDayCounts = {};

  Future<void> syncRemote({String? day}) async {
    final token =
        AuthSession.instance.accessToken ?? DemoSession.instance.accessToken;
    if (token == null || !DemoSession.instance.signedIn) return;
    final targetDay = day ?? AttendanceClock.key(AttendanceClock.today);

    try {
      if (DemoSession.instance.isAdmin) {
        await _syncAdminLunchForDay(targetDay, token);
        final todayStr = AttendanceClock.key(AttendanceClock.today);
        if (targetDay == todayStr) {
          final tomorrowStr = AttendanceClock.key(
              AttendanceClock.today.add(const Duration(days: 1)));
          await _syncAdminLunchForDay(tomorrowStr, token);
        }
      } else {
        final myLunch =
            await _lunchApi.getMyLunch(date: targetDay, token: token);
        if (token != AuthSession.instance.accessToken) return;
        if (myLunch['policy'] is Map) {
          policy = Map<String, dynamic>.from(myLunch['policy'] as Map);
        }
        final myId = DemoSession.instance.employeeId;
        final updated = List<LunchPreference>.from(_changes);

        void recordDay(Map dayMap) {
          final dayDate = dayMap['date']?.toString();
          if (dayDate == null) return;
          final taking = dayMap['taking_lunch'] == true;
          updated.removeWhere(
              (c) => _matchesEmployee(c.employeeId, myId) && c.day == dayDate);
          updated.add(LunchPreference(
            employeeId: myId,
            day: dayDate,
            takeLunch: taking,
            actorId: myId,
            updatedAt: AttendanceClock.now,
            mealPreference: dayMap['meal_preference']?.toString() ?? 'regular',
            note: dayMap['note']?.toString(),
            serverStatus: dayMap['status']?.toString(),
            canChange: dayMap['can_change'] as bool?,
          ));
        }

        if (myLunch['selected'] is Map) {
          recordDay(myLunch['selected'] as Map);
        }
        final nextDays = myLunch['next_days'];
        if (nextDays is List) {
          for (final d in nextDays) {
            if (d is Map) recordDay(d);
          }
        }
        _changes = List.unmodifiable(updated);
        notifyListeners();
      }
      remoteError = null;
      notifyListeners();
    } catch (e) {
      remoteError =
          e is FormatException ? e.message : 'Lunch could not be refreshed.';
      notifyListeners();
    }
  }

  Future<void> _syncAdminLunchForDay(String dayDate, String token) async {
    final lunchRes = await _lunchApi.roster(dayDate, token: token);
    if (token != AuthSession.instance.accessToken) return;
    if (lunchRes['settings'] is Map) {
      policy = Map<String, dynamic>.from(lunchRes['settings'] as Map);
    }
    final staff = lunchRes['staff'];
    if (staff is List) {
      final updated = List<LunchPreference>.from(_changes);
      for (final item in staff) {
        if (item is Map) {
          final rawId = item['employee_id'] ?? item['id'];
          final taking = item['taking_lunch'] == true;
          if (rawId == null) continue;
          final empId = 'api_emp_$rawId';
          updated.removeWhere(
              (c) => _matchesEmployee(c.employeeId, empId) && c.day == dayDate);
          updated.add(LunchPreference(
            employeeId: empId,
            day: dayDate,
            takeLunch: taking,
            actorId: 'admin',
            updatedAt: AttendanceClock.now,
            mealPreference: item['meal_preference']?.toString() ?? 'regular',
            note: item['note']?.toString(),
            serverStatus: item['status']?.toString(),
            canChange: item['can_change'] as bool?,
          ));
        }
      }
      _changes = List.unmodifiable(updated);

      final needed = (lunchRes['lunches_to_provide'] as num?)?.toInt() ??
          staff.whereType<Map>().where((r) => r['taking_lunch'] == true).length;
      final skipping = (lunchRes['skipping_lunch'] as num?)?.toInt() ??
          staff
              .whereType<Map>()
              .where((r) =>
                  r['status'] == 'skipping_lunch' ||
                  r['status'] == 'not_taking_lunch' ||
                  (r['taking_lunch'] == false &&
                      r['status'] != 'day_off' &&
                      r['status'] != 'on_leave' &&
                      r['status'] != 'inactive'))
              .length;
      final eligible =
          (lunchRes['eligible_staff'] as num?)?.toInt() ?? (needed + skipping);
      remoteDayCounts[dayDate] = {
        'needed': needed,
        'skipped': skipping,
        'eligible': eligible,
      };
      notifyListeners();
    }
  }

  LunchPreference? preferenceFor(String employeeId, String day) => _changes
      .where((change) =>
          _matchesEmployee(change.employeeId, employeeId) && change.day == day)
      .lastOrNull;

  List<LunchPreference> changesByActor(String actorId) =>
      DemoSession.instance.isAdmin
          ? List.unmodifiable(_changes.where((change) =>
              change.actorId == actorId &&
              EmployeeStore.instance.isStaffEmployee(change.employeeId)))
          : const [];

  List<LunchPreference> historyFor(String? employeeId, String day) => _changes
      .where((change) =>
          EmployeeStore.instance.isStaffEmployee(change.employeeId) &&
          (employeeId == null || change.employeeId == employeeId) &&
          change.day == day)
      .toList()
      .reversed
      .toList();

  LunchStatus statusFor(String employeeId, String day) {
    final remote = preferenceFor(employeeId, day);
    if (remote?.serverStatus != null) {
      return switch (remote!.serverStatus) {
        'day_off' => LunchStatus.offDay,
        'on_leave' => LunchStatus.leave,
        'inactive' => LunchStatus.inactive,
        'not_scheduled' => LunchStatus.notIncluded,
        'skipping_lunch' || 'not_taking_lunch' => LunchStatus.skipped,
        'taking_lunch' => LunchStatus.receiving,
        _ => remote.takeLunch ? LunchStatus.receiving : LunchStatus.skipped,
      };
    }
    final employee = EmployeeStore.instance.byId(employeeId);
    if (employee == null || employee.status != 'Active') {
      return LunchStatus.inactive;
    }
    if (!EmployeeStore.instance.isStaffEmployee(employeeId)) {
      return LunchStatus.notIncluded;
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
    if (administrator) return difference >= 0;
    if (policy['is_enabled'] == false || difference < 0) return false;
    final pref = preferenceFor(DemoSession.instance.employeeId, day);
    if (difference > 0) return pref?.canChange ?? true;
    final parts = policy['cutoff_time']?.toString().split(':');
    if (parts == null || parts.length < 2) return false;
    final now = AttendanceClock.wallTime(AttendanceClock.now);
    return pref?.canChange != false &&
        now.hour * 60 + now.minute <
            (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  Future<void> loadMonthly(String month, {bool force = false}) async {
    if (DemoSession.instance.isAdmin ||
        !AuthSession.instance.signedIn ||
        (!force && _monthlyKey == month)) {
      return;
    }
    final token = AuthSession.instance.accessToken!;
    try {
      final result = await _lunchApi.monthly(month, token: token);
      if (token != AuthSession.instance.accessToken) return;
      monthlySummary = result;
      _monthlyKey = month;
      _monthError = null;
    } catch (e) {
      if (token == AuthSession.instance.accessToken) {
        _monthError = e is FormatException
            ? e.message
            : 'Monthly lunch summary is unavailable.';
      }
    }
    notifyListeners();
  }

  Future<void> updateSettings(Map<String, dynamic> body) async {
    if (!DemoSession.instance.isAdmin) {
      throw const FormatException('Administrator access is required.');
    }
    final token = AuthSession.instance.accessToken!;
    final response = await _lunchApi.updateSettings(body, token: token);
    if (token != AuthSession.instance.accessToken) return;
    if (response['settings'] is Map) {
      policy = Map<String, dynamic>.from(response['settings'] as Map);
    } else {
      final result = await _lunchApi.settings(token: token);
      if (token == AuthSession.instance.accessToken) {
        policy = Map<String, dynamic>.from(result['settings'] as Map? ?? {});
      }
    }
    notifyListeners();
  }

  Future<void> setLunch(
      {required String employeeId,
      required String day,
      required bool takeLunch,
      required String actorId,
      String? mealPreference,
      String? note}) async {
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
      if (AttendanceStore.instance.loadError != null) {
        throw FormatException(AttendanceStore.instance.loadError!);
      }
      final actor = EmployeeStore.instance.byId(actorId);
      final isAdmin = AttendanceStore.instance.isAdministrator(actorId);
      if (!EmployeeStore.instance.isStaffEmployee(employeeId)) {
        throw const FormatException(
            'Office lunch preferences are available for staff accounts.');
      }
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
            'The lunch change deadline has passed for this date.');
      }
      if (!statusFor(employeeId, day).available) {
        throw const FormatException(
            'Lunch is unavailable on days off, approved full-day leave, or inactive accounts.');
      }
      if (mealPreference == null &&
          note == null &&
          (statusFor(employeeId, day) == LunchStatus.receiving) == takeLunch) {
        return;
      }
      final token = AuthSession.instance.accessToken;
      if (token != null) {
        if (isAdmin && actorId != employeeId) {
          await AttendanceStore.instance.api.manageStaffLunch(
              employeeId.replaceFirst('api_emp_', ''),
              {
                'taking_lunch': takeLunch,
                'lunch_date': day,
                if (mealPreference != null) 'meal_preference': mealPreference,
                if (note != null) 'note': note
              },
              token: token);
        } else {
          await _lunchApi.updateMyLunch(
              lunchDate: day,
              takingLunch: takeLunch,
              mealPreference: mealPreference,
              note: note,
              token: token);
        }
        if (token != AuthSession.instance.accessToken) return;
      }
      final previous = preferenceFor(employeeId, day);
      final updated = [
        ..._changes,
        LunchPreference(
            employeeId: employeeId,
            day: day,
            takeLunch: takeLunch,
            actorId: actorId,
            updatedAt: AttendanceClock.now,
            mealPreference:
                mealPreference ?? previous?.mealPreference ?? 'regular',
            note: note ?? previous?.note,
            serverStatus: takeLunch ? 'taking_lunch' : 'skipping_lunch',
            canChange: previous?.canChange)
      ];
      final prefs = await SharedPreferences.getInstance();
      if (accountToken != _accountToken) {
        throw const FormatException('Your account changed.');
      }
      if (!await prefs.setString(
          storageKey,
          jsonEncode({
            'version': 1,
            'changes': updated.map((change) => change.toJson()).toList()
          }))) {
        throw const FormatException(
            'Lunch preference could not be saved. Please try again.');
      }
      _changes = List.unmodifiable(updated);
      notifyListeners();
      await syncRemote(day: day);
      if (!isAdmin) await loadMonthly(day.substring(0, 7), force: true);
    });
    _pending = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    await write;
  }
}
