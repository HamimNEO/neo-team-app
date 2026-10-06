import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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

final List<SystemRoleItem> mockSystemRoles = [
  SystemRoleItem(
    id: 'role_super_admin',
    name: 'Super Admin',
    badge: 'SYSTEM',
    description: 'Full system access — all modules and settings',
    memberCount: 1,
    iconColor: AppColors.error,
    scope: 'Full access',
    lastUpdated: 'Sep 20, 2024',
    memberNames: const ['Rahul Sharma'],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_admin',
    name: 'Admin',
    badge: 'SYSTEM',
    description: 'Admin & operational',
    memberCount: 2,
    iconColor: const Color(0xFFAF52DE),
    scope: 'Admin & ops',
    lastUpdated: 'Sep 18, 2024',
    memberNames: const ['Mahmud Hasan', 'Razia Sultana'],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_manager',
    name: 'Manager',
    badge: 'SYSTEM',
    description: 'Team & operational',
    memberCount: 3,
    iconColor: AppColors.warning,
    scope: 'Team management',
    lastUpdated: 'Sep 15, 2024',
    memberNames: const ['Most. Shahina Akter', 'Karim Hossain', 'Anika Tasnim'],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_sales',
    name: 'Sales',
    badge: 'SYSTEM',
    description: 'Lead & customer ops',
    memberCount: 8,
    iconColor: AppColors.brandLight,
    scope: 'Sales operations',
    lastUpdated: 'Sep 10, 2024',
    memberNames: const ['Rashidul Islam', 'Tania Rahman', 'Rafiq Ahmed'],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_support',
    name: 'Support',
    badge: 'SYSTEM',
    description: 'Issues & support',
    memberCount: 4,
    iconColor: AppColors.success,
    scope: 'Customer support',
    lastUpdated: 'Sep 05, 2024',
    memberNames: const ['Priya Nair', 'Md. Yeapas'],
    modulePermissions: defaultModulePermissions,
  ),
  SystemRoleItem(
    id: 'role_sales_manager',
    name: 'Sales Manager',
    badge: 'CUSTOM',
    description: 'Sales + assignment',
    memberCount: 2,
    iconColor: const Color(0xFF30B0C7),
    scope: 'Sales management',
    lastUpdated: 'Aug 28, 2024',
    memberNames: const ['Fatima Al Rashid'],
    modulePermissions: defaultModulePermissions,
  ),
];

SystemRoleItem getRoleById(String id) {
  return mockSystemRoles.firstWhere(
    (r) => r.id == id,
    orElse: () => mockSystemRoles.first,
  );
}
