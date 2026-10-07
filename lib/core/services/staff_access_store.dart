import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'demo_session.dart';

enum StaffPermission {
  leads('Leads', 'View leads and their details'),
  tasks('Tasks', 'View and complete tasks'),
  followUps('Follow-ups', 'View and complete follow-ups'),
  visits('Visits', 'View visits and submit visit reports'),
  issues('Issues', 'View issues'),
  attendance('My Attendance',
      'Check in/out, leave, fixes, off-day swaps and overtime'),
  meals('Office Lunch', 'View and change upcoming lunch preferences'),
  activity('Activity', 'View activity history'),
  createLead('Create Leads', 'Add new leads'),
  editLead('Edit Leads', 'Change existing lead details'),
  createTask('Create Tasks', 'Add new tasks'),
  editTask('Edit Tasks', 'Change existing task details'),
  scheduleFollowUp('Schedule Follow-ups', 'Create follow-up appointments'),
  scheduleVisit('Schedule Visits', 'Create visit appointments'),
  reportIssue('Report Issues', 'Submit new issues');

  final String label;
  final String description;

  const StaffPermission(this.label, this.description);

  StaffPermission? get parent => switch (this) {
        createLead || editLead => leads,
        createTask || editTask => tasks,
        scheduleFollowUp => followUps,
        scheduleVisit => visits,
        reportIssue => issues,
        _ => null,
      };
}

/// Saved permissions shared by all demo staff logins; admin always has access.
class StaffAccessStore extends ChangeNotifier {
  StaffAccessStore._();

  static final instance = StaffAccessStore._();
  static const _key = 'nec_staff_access_v1';
  Map<StaffPermission, bool> _permissions = {
    for (final permission in StaffPermission.values)
      permission: permission != StaffPermission.activity,
  };
  Future<void>? _loading;
  Future<void> _pending = Future<void>.value();
  String? loadError;

  bool enabled(StaffPermission permission) => _permissions[permission] ?? false;

  bool allows(StaffPermission permission) =>
      DemoSession.instance.signedIn &&
      (DemoSession.instance.isAdmin ||
          (enabled(permission) &&
              (permission.parent == null || enabled(permission.parent!))));

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) {
        return;
      }
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      _permissions = {
        for (final permission in StaffPermission.values)
          permission: json[permission.name] as bool? ?? enabled(permission)
      };
    } catch (_) {
      loadError =
          'Staff access settings could not be loaded. Restart the app before editing them.';
      _permissions = {
        for (final permission in StaffPermission.values) permission: false
      };
    }
  }

  Future<void> setPermission(StaffPermission permission, bool enabled) async {
    await load();
    final write = _pending.then((_) async {
      if (!DemoSession.instance.isAdmin) {
        throw const FormatException('Admin access is required.');
      }
      if (loadError != null) {
        throw FormatException(loadError!);
      }
      final updated = {..._permissions, permission: enabled};
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
          _key,
          jsonEncode({
            for (final entry in updated.entries) entry.key.name: entry.value
          }))) {
        throw const FormatException(
            'Unable to save staff access. Please try again.');
      }
      _permissions = updated;
      notifyListeners();
    });
    _pending = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    await write;
  }

  bool canOpen(String path) {
    if (!DemoSession.instance.signedIn) {
      return false;
    }
    if (DemoSession.instance.isAdmin) {
      return true;
    }
    if (path == '/attendance/employee/${DemoSession.instance.employeeId}' ||
        path == '/attendance') {
      return allows(StaffPermission.attendance);
    }
    if (path.startsWith('/attendance/') || path == '/meals/admin') {
      return false;
    }
    if (path == '/meals') {
      return allows(StaffPermission.meals);
    }
    if (path.startsWith('/leads')) {
      return allows(StaffPermission.leads);
    }
    if (path == '/add-lead') {
      return allows(StaffPermission.createLead);
    }
    if (path.startsWith('/edit-lead/')) {
      return allows(StaffPermission.editLead);
    }
    if (path.startsWith('/tasks')) {
      return allows(StaffPermission.tasks);
    }
    if (path == '/create-task') {
      return allows(StaffPermission.createTask);
    }
    if (path.startsWith('/edit-task/')) {
      return allows(StaffPermission.editTask);
    }
    if (path == '/follow-ups' || path.startsWith('/follow-up-details/')) {
      return allows(StaffPermission.followUps);
    }
    if (path == '/visits' || path.startsWith('/visit-details/')) {
      return allows(StaffPermission.visits);
    }
    if (path == '/issues') {
      return allows(StaffPermission.issues);
    }
    if (path == '/report-issue') {
      return allows(StaffPermission.reportIssue);
    }
    if (path == '/activity') {
      return allows(StaffPermission.activity);
    }
    if (path == '/messages' || path.startsWith('/messages/')) {
      return true;
    }
    if (path.startsWith('/employee/')) {
      return true;
    }
    return const {
      '/home',
      '/more',
      '/profile',
      '/edit-profile',
      '/settings',
      '/account-security',
      '/change-password',
      '/appearance',
      '/permissions',
      '/about',
      '/notifications',
      '/notification-preferences',
      '/search',
      '/my-access',
      '/access-denied'
    }.contains(path);
  }
}
