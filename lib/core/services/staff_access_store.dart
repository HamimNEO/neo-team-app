import 'dart:convert';
import '../notifiers/frame_safe_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/more/data/more_store.dart';
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

class StaffAccessStore extends FrameSafeNotifier {
  StaffAccessStore._() {
    DemoSession.instance.addListener(_sessionChanged);
  }

  String? _token;
  Map<StaffPermission, bool> _apiPermissions = {};
  bool _administrationManage = false;

  bool get canManageAdministration =>
      DemoSession.instance.signedIn &&
      (DemoSession.instance.isAdmin || _administrationManage);

  void _sessionChanged() {
    final token = DemoSession.instance.accessToken;
    if (_token == token) return;
    _token = token;
    _apiPermissions = {};
    _administrationManage = false;
    _loading = null;
    loadError = null;
    notifyListeners();
    if (token != null) Future.microtask(() => load());
  }

  static final instance = StaffAccessStore._();
  static const _key = 'nec_staff_access_v1';
  Map<StaffPermission, bool> _permissions = {
    for (final permission in StaffPermission.values)
      permission: permission != StaffPermission.activity,
  };
  Future<void>? _loading;
  Future<void> _pending = Future<void>.value();
  String? loadError;

  bool enabled(StaffPermission permission) =>
      _apiPermissions[permission] ?? _permissions[permission] ?? false;

  bool allows(StaffPermission permission) =>
      DemoSession.instance.signedIn &&
      (DemoSession.instance.isAdmin ||
          (_hasApiModule(permission) &&
              enabled(permission) &&
              (permission.parent == null || enabled(permission.parent!))));

  bool _hasApiModule(StaffPermission permission) {
    if ([StaffPermission.attendance, StaffPermission.meals]
        .contains(permission)) {
      return true;
    }
    final module = switch (permission.parent ?? permission) {
      StaffPermission.leads => 'leads',
      StaffPermission.tasks => 'tasks',
      StaffPermission.followUps => 'followups',
      StaffPermission.visits => 'visits',
      StaffPermission.issues => 'issues',
      StaffPermission.attendance => 'attendance',
      StaffPermission.meals => 'meals',
      StaffPermission.activity => 'activity',
      _ => '',
    };
    return DemoSession.instance.user?.modules.contains(module) ?? false;
  }

  Future<void> load({bool force = false}) {
    if (force) _loading = null;
    return _loading ??= _load();
  }

  Future<void> restoreLocalPermissions() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      _permissions = {
        for (final permission in StaffPermission.values)
          permission: json[permission.name] as bool? ?? enabled(permission)
      };
    } catch (_) {
      // Use the existing local defaults if storage is unavailable.
    }
  }

  Future<void> _load() async {
    final token = DemoSession.instance.accessToken;
    _token = token;
    try {
      await restoreLocalPermissions();

      if (DemoSession.instance.signedIn) {
        final accessData = await MoreStore.instance.loadMyAccess();
        if (token != DemoSession.instance.accessToken) return;
        _administrationManage = false;
        if (accessData != null && accessData['modules'] is List) {
          final modules = accessData['modules'] as List;
          for (final m in modules) {
            if (m is Map) {
              final key = m['key']?.toString();
              final enabled = m['enabled'] == true;
              final perms = (m['permissions'] as List?)
                      ?.map((p) => p.toString())
                      .toSet() ??
                  {};
              if (key == 'leads') {
                _apiPermissions[StaffPermission.leads] = enabled;
                _apiPermissions[StaffPermission.createLead] =
                    perms.contains('team.leads.create');
                _apiPermissions[StaffPermission.editLead] =
                    perms.contains('team.leads.update');
              } else if (key == 'tasks') {
                _apiPermissions[StaffPermission.tasks] = enabled;
                _apiPermissions[StaffPermission.createTask] =
                    perms.contains('team.tasks.create');
                _apiPermissions[StaffPermission.editTask] =
                    perms.contains('team.tasks.update');
              } else if (key == 'followups') {
                _apiPermissions[StaffPermission.followUps] = enabled;
                _apiPermissions[StaffPermission.scheduleFollowUp] =
                    perms.contains('team.followups.create');
              } else if (key == 'visits') {
                _apiPermissions[StaffPermission.visits] = enabled;
                _apiPermissions[StaffPermission.scheduleVisit] =
                    perms.contains('team.visits.create');
              } else if (key == 'issues') {
                _apiPermissions[StaffPermission.issues] = enabled;
                _apiPermissions[StaffPermission.reportIssue] =
                    perms.contains('team.issues.create');
              } else if (key == 'administration') {
                _administrationManage =
                    enabled && perms.contains('team.administration.manage');
              }
            }
          }
        }
      }
    } catch (_) {
      if (token != DemoSession.instance.accessToken) return;
      loadError =
          'Staff access settings could not be loaded. Restart the app before editing them.';
      _apiPermissions = {};
      _administrationManage = false;
    } finally {
      if (token == DemoSession.instance.accessToken) notifyListeners();
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
    if (path == '/auto-sms-settings' ||
        path == '/follow-up-visit-settings' ||
        path == '/administration' ||
        path.startsWith('/administration/') ||
        path == '/role-permissions' ||
        path.startsWith('/role-details/') ||
        path == '/new-role' ||
        path == '/permission-catalog') {
      return canManageAdministration;
    }
    if (const {
      '/policy/privacy-policy',
      '/policy/terms-and-conditions',
      '/policy/data-deletion',
      '/policy/data-collection',
      '/policy/support',
      '/privacy-policy',
      '/terms-and-conditions',
      '/data-deletion',
      '/data-collection',
      '/support',
    }.contains(path)) {
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
    if (path == '/issues' || path.startsWith('/issues/')) {
      return allows(StaffPermission.issues);
    }
    if (path == '/report-issue') {
      return allows(StaffPermission.reportIssue);
    }
    if (path == '/activity') {
      return allows(StaffPermission.activity);
    }
    if (path == '/messages' ||
        path.startsWith('/messages/') ||
        path.startsWith('/message-groups/')) {
      return true;
    }
    if (path.startsWith('/employee/')) {
      return true;
    }
    if (path == '/certificates/admin') return false;
    if (path == '/certificates' || path == '/certificates/my') {
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
