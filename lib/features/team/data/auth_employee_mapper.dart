import '../../auth/domain/models/auth_user.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_media_url.dart';
import '../domain/models/employee.dart';
import '../../../core/constants/app_constants.dart';

/// Adapts the authenticated identity to existing profile/greeting widgets.
/// Employee management, salary and work data remain separate feature work.
Employee authEmployee(AuthUser user, String localId) {
  String field(String key) => user.employee[key]?.toString() ?? '';
  String label(String key) {
    final value = user.employee[key];
    return value is Map ? value['name']?.toString() ?? '' : field(key);
  }

  return Employee(
    id: localId,
    name: user.name,
    designation: field('designation'),
    department: label('department'),
    team: label('team'),
    systemRole: user.isSuperAdmin ? 'Administrator' : user.role,
    status: 'Active',
    email: user.email,
    phone: user.phone ?? '',
    avatarInitials: Employee.initialsFor(user.name),
    avatarAsset: user.isSuperAdmin ? AppConstants.superAdminAvatarAsset : null,
    joinedDate: field('joining_date').isNotEmpty
        ? field('joining_date')
        : field('joined_date'),
    photoUrl: user.isSuperAdmin
        ? null
        : apiMediaUrl(user.photo, AppConfig.apiBaseUrl),
    roleKey: user.role,
    accessScope: user.accessScope,
    departmentId: user.employee['department'] is Map
        ? (user.employee['department'] as Map)['id']?.toString()
        : null,
    totalMealCost: 0,
    employeeCode: field('code'),
  );
}
