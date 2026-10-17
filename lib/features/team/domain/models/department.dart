import 'employee.dart';

/// Department values come only from the API or a saved API response.
class DepartmentItem {
  const DepartmentItem({
    required this.id,
    required this.name,
    this.code,
    this.isActive,
    this.leadName,
    this.leadEmployeeId,
    this.memberCount,
    this.teamCount,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.members,
  });

  final String id, name;
  final String? code, leadName, description, createdAt, updatedAt;
  final String? leadEmployeeId;
  final bool? isActive;
  final List<Employee>? members;
  final int? memberCount, teamCount;

  String? get status => isActive == null
      ? null
      : isActive!
          ? 'Active'
          : 'Inactive';

  factory DepartmentItem.fromJson(Map<String, dynamic> json) {
    String? text(dynamic value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;
    int? count(dynamic value) => value is int && value >= 0 ? value : null;
    final id = json['id']?.toString();
    final name = text(json['name']);
    if (id == null || id.isEmpty || name == null) {
      throw const FormatException('The server returned an invalid department.');
    }
    final manager = json['manager'];
    final active = json['is_active'];
    return DepartmentItem(
      id: id,
      name: name,
      code: text(json['code']),
      isActive: active is bool
          ? active
          : active == 1
              ? true
              : active == 0
                  ? false
                  : null,
      leadName: text(json['lead_name']) ??
          (manager is Map ? text(manager['name']) : text(manager)),
      leadEmployeeId: (json['lead_employee_id'] ??
              json['lead_id'] ??
              json['manager_employee_id'] ??
              (manager is Map
                  ? (manager['employee_id'] ?? manager['id'])
                  : null))
          ?.toString(),
      memberCount: count(json['members_count']) ??
          count(json['employees_count']) ??
          count(json['member_count']),
      teamCount: count(json['teams_count']) ?? count(json['team_count']),
      description: text(json['description']),
      createdAt: text(json['created_at']),
      updatedAt: text(json['updated_at']),
      members: json['members'] is List
          ? (json['members'] as List)
              .map((member) =>
                  Employee.fromJson(Map<String, dynamic>.from(member as Map)))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'is_active': isActive,
        'lead_name': leadName,
        'lead_employee_id': leadEmployeeId,
        'members_count': memberCount,
        'teams_count': teamCount,
        'description': description,
        'created_at': createdAt,
        'updated_at': updatedAt,
        if (members != null)
          'members': members!.map((member) => member.toJson()).toList(),
      };
}
