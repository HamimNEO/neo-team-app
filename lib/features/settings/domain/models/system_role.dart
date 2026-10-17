import 'package:flutter/material.dart';

class ModulePermission {
  final String moduleName;
  final Color dotColor;
  final String accessLevel;
  final List<(String name, bool isGranted)> permissions;
  final Map<String, String> permissionKeys;

  const ModulePermission({
    required this.moduleName,
    required this.dotColor,
    this.accessLevel = 'Full Access',
    required this.permissions,
    this.permissionKeys = const {},
  });

  ModulePermission copyWith({
    String? moduleName,
    Color? dotColor,
    String? accessLevel,
    List<(String name, bool isGranted)>? permissions,
  }) {
    return ModulePermission(
      moduleName: moduleName ?? this.moduleName,
      dotColor: dotColor ?? this.dotColor,
      accessLevel: accessLevel ?? this.accessLevel,
      permissions: permissions ?? this.permissions,
      permissionKeys: permissionKeys,
    );
  }
}

class SystemRoleItem {
  final String id;
  final String name;
  final String badge;
  final String description;
  final int memberCount;
  final Color iconColor;
  final String scope;
  final String lastUpdated;
  final List<String> memberNames;
  final List<ModulePermission> modulePermissions;

  const SystemRoleItem({
    required this.id,
    required this.name,
    this.badge = 'SYSTEM',
    required this.description,
    required this.memberCount,
    required this.iconColor,
    required this.scope,
    this.lastUpdated = '',
    this.memberNames = const [],
    required this.modulePermissions,
  });

  SystemRoleItem copyWith({
    String? id,
    String? name,
    String? badge,
    String? description,
    int? memberCount,
    Color? iconColor,
    String? scope,
    String? lastUpdated,
    List<String>? memberNames,
    List<ModulePermission>? modulePermissions,
  }) {
    return SystemRoleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      badge: badge ?? this.badge,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      iconColor: iconColor ?? this.iconColor,
      scope: scope ?? this.scope,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      memberNames: memberNames ?? this.memberNames,
      modulePermissions: modulePermissions ?? this.modulePermissions,
    );
  }
}
