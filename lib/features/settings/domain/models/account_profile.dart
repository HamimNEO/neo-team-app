import '../../../auth/domain/models/auth_user.dart';
import '../../../team/domain/models/employee.dart';

/// Backend profile identity and employee management data; absent fields stay empty.
class AccountProfile {
  const AccountProfile({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.organization,
    this.status,
    this.accessScope,
    this.address,
    this.employeeCode,
    this.designation,
    this.department,
    this.team,
    this.employeeProfile,
    this.work = const {},
    this.activity = const [],
  });

  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final String? organization;
  final String? status;
  final String? accessScope;
  final String? address;
  final String? employeeCode;
  final String? designation;
  final String? department;
  final String? team;
  final Employee? employeeProfile;
  final Map<String, dynamic> work;
  final List<Map<String, dynamic>> activity;

  static int workCount(Object? value) =>
      value is Map ? workCount(value['count']) : int.tryParse('$value') ?? 0;

  static String? _text(Object? value) {
    if (value is Map) return _text(value['name']);
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw const FormatException('The server returned an invalid profile.');
    }
    final employee = json['employee'] is Map ? json['employee'] as Map : {};
    return AccountProfile(
      id: json['id'].toString(),
      name: _text(json['name']),
      email: _text(json['email']),
      phone: _text(json['phone']),
      role: _text(json['role']),
      organization: _text(json['organization']),
      status: _text(json['status']),
      accessScope: _text(json['access_scope']),
      address: _text(json['address']),
      employeeCode: _text(employee['code'] ??
          employee['employee_code'] ??
          employee['employee_id'] ??
          json['employee_code']),
      designation: _text(employee['designation'] ?? json['designation']),
      department: _text(employee['department'] ?? json['department']),
      team: _text(employee['team'] ?? json['team']),
      employeeProfile: json['employee_profile'] is Map
          ? Employee.fromJson(
              Map<String, dynamic>.from(json['employee_profile'] as Map))
          : null,
      work: Map<String, dynamic>.from(json['work'] as Map? ?? {}),
      activity: (json['activity'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }

  /// Reliable login fields can render while the profile request is in flight.
  factory AccountProfile.fromAuthUser(AuthUser user) =>
      AccountProfile.fromJson({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'role': user.role,
        'access_scope': user.employee['access_scope'],
        'employee': user.employee,
      });

  static String? displayLabel(String? value) {
    if (value == null) return null;
    return value
        .split(RegExp(r'[_\s]+'))
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String? get roleLabel => displayLabel(role);

  String? get statusLabel => displayLabel(status);

  String? get accessLabel => displayLabel(accessScope);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'organization': organization,
        'status': status,
        'access_scope': accessScope,
        'address': address,
        'employee_profile': employeeProfile?.toJson(),
        'work': work,
        'activity': activity,
        'employee': {
          'code': employeeCode,
          'designation': designation,
          'department': department,
          'team': team,
        },
      };
}
