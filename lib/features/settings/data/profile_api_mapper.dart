import '../../team/data/employee_api_mapper.dart';
import '../../team/domain/models/employee.dart';
import '../domain/models/account_profile.dart';

AccountProfile accountProfileFromApi(
    Map<String, dynamic> response, String baseUrl) {
  final identity = Map<String, dynamic>.from(response['profile'] as Map);
  final raw = identity['employee'];
  final employment = response['employment'] is Map
      ? Map<String, dynamic>.from(response['employment'] as Map)
      : <String, dynamic>{};
  final work = response['work'] is Map
      ? Map<String, dynamic>.from(response['work'] as Map)
      : <String, dynamic>{};
  Employee? employee;
  final empCode = employment['employee_id'] ??
      (raw is Map ? (raw['employee_code'] ?? raw['code']) : null);
  if (raw is Map && raw['id'] != null && raw['id'] != 0) {
    final rawBenefits = response['benefits'];
    final Map<String, dynamic> benefits = {};
    if (rawBenefits is Map) {
      benefits.addAll(Map<String, dynamic>.from(rawBenefits));
    } else if (rawBenefits is List) {
      for (final item in rawBenefits) {
        if (item is Map) {
          benefits.addAll(Map<String, dynamic>.from(item));
        }
      }
    }
    final mapped = employeeFromApi({
      ...raw,
      ...benefits,
      'name': identity['name'] ?? raw['name'],
      'email': identity['email'] ?? employment['work_email'] ?? raw['email'],
      'phone': identity['phone'] ?? employment['phone'] ?? raw['phone'],
      'photo': identity['photo'] ?? raw['photo'],
      'photo_url': identity['photo_url'] ?? raw['photo_url'],
      'employee_code': empCode,
      'designation': employment['designation'] ?? raw['designation'],
      'department_name': employment['department'],
      'team': employment['team'] ?? raw['team'],
      'joining_date': employment['joined_at'] ?? raw['joining_date'],
      'reporting_manager_name':
          employment['reports_to'] ?? raw['reporting_manager_name'],
      'address': identity['address'] ?? employment['address'] ?? raw['address'],
      'date_of_birth': employment['date_of_birth'] ?? raw['date_of_birth'],
      'emergency_contact':
          employment['emergency_contact'] ?? raw['emergency_contact'],
      'role': {
        'key': identity['role'],
        'name': employment['system_role'] ?? identity['role']
      },
      'access_scope': identity['access_scope'],
      if (response['salary'] is Map) 'salary': response['salary'],
      'activity': response['activity'] ?? [],
    }, baseUrl);
    employee = Employee.fromJson({
      ...mapped.toJson(),
      'activeLeadsCount': AccountProfile.workCount(work['leads']),
      'activeTasksCount': AccountProfile.workCount(work['tasks']),
    });
  }
  if (raw is Map) {
    identity['employee'] = {
      ...Map<String, dynamic>.from(raw),
      'code': empCode,
      'employee_code': empCode,
      'designation': employment['designation'] ?? raw['designation'],
      'department': employment['department'] ?? raw['department'],
      'team': employment['team'] ?? raw['team'],
    };
  }
  return AccountProfile.fromJson({
    ...identity,
    if (empCode != null) 'employee_code': empCode,
    'employee_profile': employee?.toJson(),
    'work': work,
    'activity': response['activity'] ?? [],
  });
}
