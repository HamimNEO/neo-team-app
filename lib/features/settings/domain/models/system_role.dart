import 'package:flutter/material.dart';

class ModulePermission {
  final String moduleName;
  final Color dotColor;
  final String accessLevel;
  final List<(String name, bool isGranted)> permissions;

  const ModulePermission({
    required this.moduleName,
    required this.dotColor,
    this.accessLevel = 'Full Access',
    required this.permissions,
  });
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
    this.lastUpdated = 'Sep 20, 2024',
    this.memberNames = const ['Rahul Sharma'],
    required this.modulePermissions,
  });
}
