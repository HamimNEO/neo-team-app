import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/storage/preferences_store.dart';
import '../../../core/services/staff_access_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../domain/models/system_role.dart';
import 'datasources/admin_settings_api.dart';

/// Only server roles and permission keys are displayed or written.
class RoleStore extends FrameSafeNotifier {
  RoleStore._() {
    _token = _session.accessToken;
    _session.addListener(_sessionChanged);
  }

  static final instance = RoleStore._();
  final _session = AuthSession.instance;
  final _preferences = const PreferencesStore();
  final _api = AdminSettingsApi(ApiClient(
    baseUrl: () => AppConfig.apiBaseUrl,
    accessToken: () => AuthSession.instance.accessToken,
    onUnauthorized: AuthSession.instance.invalidate,
  ));
  String? _token, error, catalogError;
  bool loading = false, saving = false;
  Future<void>? _loading;
  List<SystemRoleItem> _roles = [];
  List<Map<String, dynamic>> _catalog = [];
  List<Map<String, dynamic>> _records = [];
  final Set<String> _detailsLoaded = {};

  List<SystemRoleItem> get roles => List.unmodifiable(_roles);

  List<Map<String, dynamic>> get catalog => List.unmodifiable(_catalog);

  bool get canManage => StaffAccessStore.instance.canManageAdministration;

  String get _cacheKey => 'nec_api_roles_v1_${_session.user!.id}';

  void _sessionChanged() {
    if (_token == _session.accessToken) return;
    _token = _session.accessToken;
    _loading = null;
    _roles = [];
    _records = [];
    _catalog = [];
    _detailsLoaded.clear();
    loading = saving = false;
    error = catalogError = null;
    notifyListeners();
  }

  SystemRoleItem? byId(String id) =>
      _roles.where((role) => role.id == id).firstOrNull;

  bool canEdit(SystemRoleItem role) =>
      canManage &&
      role.badge == 'CUSTOM' &&
      !saving &&
      _detailsLoaded.contains(role.id) &&
      _catalog.isNotEmpty &&
      catalogError == null;

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List || value.any((record) => record is! Map)) {
      throw const FormatException(
          'The server returned an invalid role catalog.');
    }
    return value
        .map((record) => Map<String, dynamic>.from(record as Map))
        .toList();
  }

  SystemRoleItem _map(Map<String, dynamic> record) {
    if (record['id'] == null || record['name'] is! String) {
      throw const FormatException('The server returned an invalid role.');
    }
    final granted = <String>{};
    final permissions = record['permissions'];
    if (permissions is List) {
      for (final permission in permissions) {
        if (permission is String) granted.add(permission);
        if (permission is Map &&
            permission['key'] is String &&
            permission['granted'] != false &&
            permission['is_granted'] != false) {
          granted.add(permission['key'] as String);
        }
      }
    }
    final modules = record['modules'];
    if (modules is List) {
      for (final module in modules.whereType<Map>()) {
        final values = module['permissions'];
        if (values is List) {
          for (final value in values) {
            if (value is String) granted.add(value);
            if (value is Map &&
                (value['granted'] == true || value['is_granted'] == true)) {
              final key = value['key'];
              if (key is String) granted.add(key);
            }
          }
        }
      }
    }
    const colors = [
      Color(0xFF007AFF),
      Color(0xFFFF9500),
      Color(0xFF30B0C7),
      Color(0xFF5856D6),
      Color(0xFFFF3B30),
      Color(0xFF34C759),
      Color(0xFFAF52DE)
    ];
    final mappedModules = <ModulePermission>[];
    for (var i = 0; i < _catalog.length; i++) {
      final module = _catalog[i];
      final keys = <String, String>{};
      final rows = <(String, bool)>[];
      for (final permission in _maps(module['permissions'])) {
        final key = permission['key'] as String;
        final label =
            (permission['label'] ?? permission['action'] ?? key).toString();
        keys[label] = key;
        rows.add((label, granted.contains(key)));
      }
      final count = rows.where((row) => row.$2).length;
      mappedModules.add(ModulePermission(
        moduleName: (module['label'] ?? module['key']).toString(),
        dotColor: colors[i % colors.length],
        permissions: rows,
        permissionKeys: keys,
        accessLevel: count == 0
            ? 'No Access'
            : count == rows.length
                ? 'Full Access'
                : 'Custom ($count/${rows.length})',
      ));
    }
    final isSystem = record['is_system'] == true ||
        record['type'] == 'system' ||
        (record['is_system'] == null &&
            record['is_custom'] != true &&
            !(record['role_key'] ?? record['key'] ?? '')
                .toString()
                .startsWith('TEAM_CUSTOM_'));
    final members = record['members'];
    return SystemRoleItem(
      id: record['id'].toString(),
      name: record['name'] as String,
      badge: isSystem ? 'SYSTEM' : 'CUSTOM',
      description: record['description']?.toString() ?? '',
      memberCount: int.tryParse(
              '${record['member_count'] ?? record['members_count']}') ??
          0,
      iconColor: isSystem ? colors.first : colors.last,
      scope: record['scope']?.toString() ??
          record['access_scope']?.toString() ??
          '',
      lastUpdated: record['updated_at']?.toString() ?? '',
      memberNames: members is List
          ? members
              .whereType<Map>()
              .map((m) => m['name']?.toString() ?? '')
              .where((n) => n.isNotEmpty)
              .toList()
          : [],
      modulePermissions: mappedModules,
    );
  }

  void _remap() => _roles = _records.map(_map).toList();

  Future<void> load() => !canManage || _token == null || saving
      ? Future.value()
      : _loading ??= _load();

  Future<void> loadCatalog() async {
    if (!canManage || _token == null) return;
    final token = _token!;
    try {
      final result = await _api.getPermissionCatalog(token);
      if (token != _token) return;
      _catalog = _maps(result['permission_modules']);
      catalogError = null;
      _remap();
    } catch (e) {
      if (token == _token) catalogError = _message(e);
    }
    if (token == _token) notifyListeners();
  }

  Future<void> _load() async {
    final token = _token!, key = _cacheKey;
    loading = true;
    error = catalogError = null;
    notifyListeners();
    try {
      if (_records.isEmpty) {
        final raw = await _preferences.read(key);
        if (token != _token) return;
        if (raw != null) {
          try {
            final cached = jsonDecode(raw) as Map;
            _catalog = _maps(cached['catalog']);
            _records = _maps(cached['roles']);
            _remap();
            notifyListeners();
          } catch (_) {}
        }
      }
      await Future.wait([
        () async {
          try {
            final result = await _api.getPermissionCatalog(token);
            if (token != _token) return;
            _catalog = _maps(result['permission_modules']);
            _remap();
            notifyListeners();
          } catch (e) {
            if (token == _token) catalogError = _message(e);
          }
        }(),
        () async {
          try {
            final result = await _api.getRoles(token);
            if (token != _token) return;
            _records = _maps(result['roles'] ?? result['data']);
            if (result['permission_modules'] is List &&
                (result['permission_modules'] as List).isNotEmpty) {
              _catalog = _maps(result['permission_modules']);
            }
            _detailsLoaded.clear();
            _remap();
            notifyListeners();
          } catch (e) {
            if (token == _token) error = _message(e);
          }
        }(),
      ]);
      if (token == _token && error == null && catalogError == null) {
        await _persist(key);
      }
    } catch (e) {
      if (token == _token) error = _message(e);
    } finally {
      if (token == _token) {
        loading = false;
        _loading = null;
        notifyListeners();
      }
    }
  }

  Future<void> loadDetail(String id) async {
    await load();
    final token = _token;
    if (token == null || !canManage) return;
    loading = true;
    notifyListeners();
    try {
      final result = await _api.getRoleDetail(token, id);
      if (token != _token) return;
      _upsert(_roleRecord(result));
      _detailsLoaded.add(id);
      error = null;
      await _persist(_cacheKey);
    } catch (e) {
      if (token == _token) error = _message(e);
    }
    if (token == _token) {
      loading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _roleRecord(Map<String, dynamic> result) {
    if (result['role'] is! Map) {
      throw const FormatException('The server did not confirm the saved role.');
    }
    return Map<String, dynamic>.from(result['role'] as Map);
  }

  void _upsert(Map<String, dynamic> record) {
    _map(record);
    _records = [
      ..._records.where((r) => '${r['id']}' != '${record['id']}'),
      record
    ];
    _remap();
  }

  Future<void> _persist(String key) async {
    try {
      await _preferences.write(
          key, jsonEncode({'catalog': _catalog, 'roles': _records}));
    } catch (_) {
      /* A confirmed server result stays visible if caching fails. */
    }
  }

  Future<SystemRoleItem> create(String name, String description) async {
    await load();
    if (catalogError != null || _catalog.isEmpty) {
      throw const FormatException(
          'Load the server permission catalog before creating a role.');
    }
    final defaults = {
      'team.leads.view',
      'team.leads.create',
      'team.followups.view',
      'team.tasks.view',
      'team.tasks.create',
      'team.team.view'
    };
    final available = _catalog
        .expand((m) => _maps(m['permissions']))
        .map((p) => p['key'])
        .toSet();
    return _save(null, {
      'name': name,
      'description': description,
      'permissions': defaults.where(available.contains).toList()
    });
  }

  Future<void> updatePermission(
      String id, String module, String label, bool grant) async {
    final role = byId(id);
    if (role == null || !canEdit(role)) {
      throw const FormatException('Only custom roles can be edited.');
    }
    final values = _grants(role);
    final key = role.modulePermissions
        .where((m) => m.moduleName == module)
        .first
        .permissionKeys[label];
    if (key == null) {
      throw const FormatException('Refresh the permission catalog.');
    }
    grant ? values.add(key) : values.remove(key);
    await _save(id, {'permissions': values.toList()});
  }

  Future<void> toggleAllModulePermissions(
      String id, String module, bool grant) async {
    final role = byId(id);
    if (role == null || !canEdit(role)) {
      throw const FormatException('Only custom roles can be edited.');
    }
    final values = _grants(role);
    final keys = role.modulePermissions
        .where((m) => m.moduleName == module)
        .first
        .permissionKeys
        .values;
    grant ? values.addAll(keys) : values.removeAll(keys);
    await _save(id, {'permissions': values.toList()});
  }

  Set<String> _grants(SystemRoleItem role) {
    final keys = <String>{};
    void collect(Object? values, {bool requireGranted = false}) {
      if (values is! List) return;
      for (final permission in values) {
        if (permission is String) keys.add(permission);
        if (permission is Map && permission['key'] is String) {
          final granted = permission['granted'] ?? permission['is_granted'];
          if (granted == true || (!requireGranted && granted != false)) {
            keys.add(permission['key'] as String);
          }
        }
      }
    }

    for (final record in _records.where((r) => '${r['id']}' == role.id)) {
      collect(record['permissions']);
      if (record['modules'] is List) {
        for (final module in (record['modules'] as List).whereType<Map>()) {
          collect(module['permissions'], requireGranted: true);
        }
      }
    }
    for (final module in role.modulePermissions) {
      for (final row in module.permissions) {
        if (row.$2 && module.permissionKeys[row.$1] != null) {
          keys.add(module.permissionKeys[row.$1]!);
        }
      }
    }
    return keys;
  }

  Future<SystemRoleItem> _save(String? id, Map<String, dynamic> payload) async {
    if (!canManage || _token == null) {
      throw const FormatException('Administrator access is required.');
    }
    if (saving) {
      throw const FormatException('A role update is already in progress.');
    }
    final token = _token!, key = _cacheKey;
    saving = true;
    notifyListeners();
    try {
      final result = id == null
          ? await _api.createRole(token, payload)
          : await _api.updateRole(token, id, payload);
      if (token != _token) {
        throw const FormatException('Your session changed. Refresh roles.');
      }
      final record = _roleRecord(result);
      if (id != null && '${record['id']}' != id) {
        throw const FormatException('The server returned a different role.');
      }
      _upsert(record);
      error = null;
      await _persist(key);
      return byId('${record['id']}')!;
    } finally {
      if (token == _token) {
        saving = false;
        notifyListeners();
      }
    }
  }

  static String _message(Object e) => e is ApiException
      ? e.message
      : e is FormatException
          ? e.message
          : 'Unable to load roles. Please retry.';
}
