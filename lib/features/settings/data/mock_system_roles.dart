import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../team/data/employee_store.dart';
import '../../team/domain/models/employee.dart';
import '../domain/models/system_role.dart';

final List<ModulePermission> defaultModulePermissions = [
  const ModulePermission(
    moduleName: 'Leads',
    dotColor: AppColors.brandLight,
    accessLevel: 'Full Access',
    permissions: [
      ('View Leads', true),
      ('View Assigned Only', true),
      ('Create Lead', true),
      ('Edit Lead', true),
      ('Assign Lead', true),
      ('Reassign Lead', true),
      ('Change Status', true),
      ('Archive / Mark Lost', true),
    ],
  ),
  const ModulePermission(
    moduleName: 'Follow-ups',
    dotColor: AppColors.warning,
    accessLevel: 'Full Access',
    permissions: [
      ('View Follow-ups', true),
      ('Schedule Follow-up', true),
      ('Edit Follow-up', true),
      ('Assign Follow-up', true),
      ('Complete Follow-up', true),
    ],
  ),
  const ModulePermission(
    moduleName: 'Visits',
    dotColor: AppColors.warning,
    accessLevel: 'Full Access',
    permissions: [
      ('View Visits', true),
      ('Schedule Visit', true),
      ('Edit Visit', true),
      ('Assign Visit', true),
      ('Complete Visit', true),
    ],
  ),
  const ModulePermission(
    moduleName: 'Tasks',
    dotColor: Color(0xFF5856D6),
    accessLevel: 'Full Access',
    permissions: [
      ('View Tasks', true),
      ('Create Task', true),
      ('Edit Task', true),
      ('Assign Task', true),
    ],
  ),
  const ModulePermission(
    moduleName: 'Issues',
    dotColor: AppColors.error,
    accessLevel: 'Full Access',
    permissions: [
      ('Report Issues', true),
      ('Edit Issues', true),
      ('Resolve Issues', true),
    ],
  ),
  const ModulePermission(
    moduleName: 'Team',
    dotColor: Color(0xFF5856D6),
    accessLevel: 'Full Access',
    permissions: [
      ('View Team Members', true),
      ('Manage Team', true),
      ('View Reports', true),
    ],
  ),
  const ModulePermission(
    moduleName: 'Administration',
    dotColor: Color(0xFF8E8E93),
    accessLevel: 'Full Access',
    permissions: [
      ('Manage Organization', true),
      ('Manage Roles', true),
      ('Audit Logs', true),
    ],
  ),
];

final List<SystemRoleItem> _initialSystemRoles = [
  SystemRoleItem(
    id: 'role_super_admin',
    name: 'Super Admin',
    badge: 'SYSTEM',
    description: 'Full system access — all modules and settings',
    memberCount: 1,
    iconColor: AppColors.error,
    scope: 'Full access',
    lastUpdated: 'Live',
    memberNames: const ['Super Admin'],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_admin',
    name: 'Admin',
    badge: 'SYSTEM',
    description: 'Admin & operational settings oversight',
    memberCount: 1,
    iconColor: const Color(0xFFAF52DE),
    scope: 'Admin & ops',
    lastUpdated: 'Live',
    memberNames: const ['Dragon (Admin)'],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_ops_manager',
    name: 'Operations Manager',
    badge: 'SYSTEM',
    description:
        'Supervises leads, tasks, follow-ups, and field visits with full operational rights.',
    memberCount: 0,
    iconColor: AppColors.warning,
    scope: 'Operational management',
    lastUpdated: 'Live',
    memberNames: const [],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_sales_exec',
    name: 'Sales Executive',
    badge: 'SYSTEM',
    description:
        'Handles sales leads, follow-ups, outreach and customer visits.',
    memberCount: 0,
    iconColor: AppColors.brandLight,
    scope: 'Sales operations',
    lastUpdated: 'Live',
    memberNames: const [],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_flutter_dev',
    name: 'Flutter Developer',
    badge: 'CUSTOM',
    description:
        'Mobile engineering role focusing on tasks, sprint tickets and issue debugging.',
    memberCount: 0,
    iconColor: const Color(0xFF30B0C7),
    scope: 'Mobile Engineering',
    lastUpdated: 'Live',
    memberNames: const [],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_backend_dev',
    name: 'Backend Developer',
    badge: 'CUSTOM',
    description:
        'Core backend engineering role with API, task, issue and administration visibility.',
    memberCount: 0,
    iconColor: const Color(0xFF5856D6),
    scope: 'Backend Engineering',
    lastUpdated: 'Live',
    memberNames: const [],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_mkt_spec',
    name: 'Digital Marketing Specialist',
    badge: 'CUSTOM',
    description:
        'Manages incoming marketing leads, campaigns, promotional tasks and follow-ups.',
    memberCount: 0,
    iconColor: const Color(0xFFFF9500),
    scope: 'Growth & Media',
    lastUpdated: 'Live',
    memberNames: const [],
    modulePermissions: defaultModulePermissions,
  ),
];

class RolePermissionsStore extends FrameSafeNotifier {
  RolePermissionsStore._() {
    load();
  }

  static final RolePermissionsStore instance = RolePermissionsStore._();
  static const String _storageKey = 'nec_role_permissions_v2';

  List<SystemRoleItem> _roles = List.from(_initialSystemRoles);
  bool _loaded = false;

  List<SystemRoleItem> get roles => List.unmodifiable(_roles);

  bool isRoleAdmin(String roleId) {
    final lower = roleId.toLowerCase();
    return lower == 'role_super_admin' ||
        lower == 'role_admin' ||
        lower.contains('super_admin') ||
        lower.contains('admin');
  }

  SystemRoleItem getRole(String id) {
    return _roles.firstWhere(
      (r) => r.id == id,
      orElse: () => _initialSystemRoles.firstWhere(
        (r) => r.id == id,
        orElse: () => _initialSystemRoles.first,
      ),
    );
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final Map<String, dynamic> data = jsonDecode(raw);
        _applySavedData(data);
      }
      _loaded = true;
      notifyListeners();
    } catch (_) {}
  }

  void _applySavedData(Map<String, dynamic> data) {
    _roles = _roles.map((role) {
      if (isRoleAdmin(role.id)) return role;
      final roleData = data[role.id];
      if (roleData is! Map<String, dynamic>) return role;

      final updatedModules = role.modulePermissions.map((mod) {
        final modData = roleData[mod.moduleName];
        if (modData is! Map<String, dynamic>) return mod;

        final updatedPerms = mod.permissions.map((p) {
          final granted = modData[p.$1];
          if (granted is bool) {
            return (p.$1, granted);
          }
          return p;
        }).toList();

        final grantedCount = updatedPerms.where((p) => p.$2).length;
        final totalCount = updatedPerms.length;
        final accessLevel = grantedCount == totalCount
            ? 'Full Access'
            : grantedCount == 0
                ? 'No Access'
                : 'Custom ($grantedCount/$totalCount)';

        return mod.copyWith(
          permissions: updatedPerms,
          accessLevel: accessLevel,
        );
      }).toList();

      return role.copyWith(modulePermissions: updatedModules);
    }).toList();
  }

  Future<void> updatePermission(
    String roleId,
    String moduleName,
    String permissionName,
    bool isGranted,
  ) async {
    if (isRoleAdmin(roleId)) return;

    final roleIndex = _roles.indexWhere((r) => r.id == roleId);
    if (roleIndex == -1) return;

    final role = _roles[roleIndex];
    final updatedModules = role.modulePermissions.map((mod) {
      if (mod.moduleName != moduleName) return mod;

      final updatedPerms = mod.permissions.map((p) {
        if (p.$1 == permissionName) {
          return (p.$1, isGranted);
        }
        return p;
      }).toList();

      final grantedCount = updatedPerms.where((p) => p.$2).length;
      final totalCount = updatedPerms.length;
      final accessLevel = grantedCount == totalCount
          ? 'Full Access'
          : grantedCount == 0
              ? 'No Access'
              : 'Custom ($grantedCount/$totalCount)';

      return mod.copyWith(
        permissions: updatedPerms,
        accessLevel: accessLevel,
      );
    }).toList();

    _roles[roleIndex] = role.copyWith(
      modulePermissions: updatedModules,
      lastUpdated: 'Just now',
    );
    notifyListeners();
    await _save();
  }

  Future<void> toggleAllModulePermissions(
    String roleId,
    String moduleName,
    bool grantAll,
  ) async {
    if (isRoleAdmin(roleId)) return;

    final roleIndex = _roles.indexWhere((r) => r.id == roleId);
    if (roleIndex == -1) return;

    final role = _roles[roleIndex];
    final updatedModules = role.modulePermissions.map((mod) {
      if (mod.moduleName != moduleName) return mod;

      final updatedPerms = mod.permissions.map((p) {
        return (p.$1, grantAll);
      }).toList();

      final accessLevel = grantAll ? 'Full Access' : 'No Access';

      return mod.copyWith(
        permissions: updatedPerms,
        accessLevel: accessLevel,
      );
    }).toList();

    _roles[roleIndex] = role.copyWith(
      modulePermissions: updatedModules,
      lastUpdated: 'Just now',
    );
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> export = {};
      for (final role in _roles) {
        if (isRoleAdmin(role.id)) continue;
        final Map<String, dynamic> roleMap = {};
        for (final mod in role.modulePermissions) {
          final Map<String, bool> modMap = {};
          for (final p in mod.permissions) {
            modMap[p.$1] = p.$2;
          }
          roleMap[mod.moduleName] = modMap;
        }
        export[role.id] = roleMap;
      }
      await prefs.setString(_storageKey, jsonEncode(export));
    } catch (_) {}
  }

  bool isPermissionGrantedForRole(
    String roleOrDesignation,
    String moduleName,
    String permName,
  ) {
    final lower = roleOrDesignation.trim().toLowerCase();
    if (lower.contains('admin')) return true;

    final matchingRole = _roles.firstWhere(
      (r) {
        final rName = r.name.toLowerCase();
        return rName == lower ||
            lower.contains(rName) ||
            rName.contains(lower) ||
            r.id.toLowerCase() == lower;
      },
      orElse: () => _roles.firstWhere(
        (r) => r.id == 'role_ops_manager',
        orElse: () => _roles.first,
      ),
    );

    final mod = matchingRole.modulePermissions.firstWhere(
      (m) => m.moduleName.toLowerCase() == moduleName.toLowerCase(),
      orElse: () => const ModulePermission(
        moduleName: '',
        dotColor: Colors.transparent,
        permissions: [],
      ),
    );

    for (final p in mod.permissions) {
      if (p.$1.toLowerCase() == permName.toLowerCase()) {
        return p.$2;
      }
    }
    return true;
  }
}

List<SystemRoleItem> get mockSystemRoles => RolePermissionsStore.instance.roles;

List<Employee> getEmployeesForRole(
    String roleName, List<Employee> liveEmployees) {
  return liveEmployees.where((emp) {
    if (emp.status != 'Active') return false;
    final roleLower = roleName.toLowerCase();
    final empRoleLower = emp.systemRole.toLowerCase();
    final empDesigLower = emp.designation.toLowerCase();

    return empRoleLower == roleLower ||
        empDesigLower.contains(roleLower) ||
        (roleLower.contains('flutter') &&
            (empDesigLower.contains('flutter') ||
                empRoleLower.contains('flutter'))) ||
        (roleLower.contains('backend') &&
            (empDesigLower.contains('backend') ||
                empRoleLower.contains('backend'))) ||
        (roleLower.contains('marketing') &&
            (empDesigLower.contains('marketing') ||
                empRoleLower.contains('marketing'))) ||
        (roleLower.contains('sales') &&
            (empDesigLower.contains('sales') ||
                empRoleLower.contains('sales'))) ||
        (roleLower.contains('operations') &&
            (empDesigLower.contains('operations') ||
                empRoleLower.contains('operations')));
  }).toList();
}

List<SystemRoleItem> buildSystemRolesWithLiveEmployees(
    List<Employee> liveEmployees,
    [List<SystemRoleItem>? baseRoles]) {
  final templates = baseRoles ?? RolePermissionsStore.instance.roles;

  return templates.map((role) {
    if (role.id == 'role_super_admin' || role.id == 'role_admin') {
      return role;
    }

    final matchingEmployees = getEmployeesForRole(role.name, liveEmployees);

    return role.copyWith(
      memberCount: matchingEmployees.length,
      memberNames: matchingEmployees.map((e) => e.name).toList(),
    );
  }).toList();
}

SystemRoleItem getRoleById(String id) {
  final role = RolePermissionsStore.instance.getRole(id);
  final enriched = buildSystemRolesWithLiveEmployees(
    EmployeeStore.instance.employees,
    [role],
  );
  return enriched.isNotEmpty ? enriched.first : role;
}
