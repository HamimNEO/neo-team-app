import 'employee.dart';

class TeamGroup {
  const TeamGroup(
      {required this.name,
      required this.memberCount,
      required this.department,
      this.lead,
      this.backendId,
      this.description,
      this.workOverview});

  final String name, department;
  final int memberCount;
  final Employee? lead;
  final String? backendId;
  final String? description;
  final Map<String, int>? workOverview;

  String get id => name;

  String get leadName => lead?.name ?? 'Not assigned';

  Map<String, dynamic> toJson() => {
        'name': name,
        'backendId': backendId,
        'memberCount': memberCount,
        'department': department,
        'lead': lead?.toJson(),
        'description': description,
        'workOverview': workOverview
      };

  factory TeamGroup.fromJson(Map<String, dynamic> json) => TeamGroup(
      name: json['name'] as String,
      backendId: json['backendId']?.toString(),
      memberCount: json['memberCount'] as int,
      department: json['department'] as String,
      description: json['description'] as String?,
      lead: json['lead'] == null
          ? null
          : Employee.fromJson(Map<String, dynamic>.from(json['lead'] as Map)),
      workOverview: json['workOverview'] == null
          ? null
          : Map<String, int>.from(json['workOverview'] as Map));
}

class TeamDetail {
  const TeamDetail(this.team, this.members);

  final TeamGroup team;
  final List<Employee> members;

  Map<String, dynamic> toJson() => {
        'team': team.toJson(),
        'members': members.map((e) => e.toJson()).toList()
      };

  factory TeamDetail.fromJson(Map<String, dynamic> json) => TeamDetail(
      TeamGroup.fromJson(Map<String, dynamic>.from(json['team'] as Map)),
      (json['members'] as List)
          .map((e) => Employee.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList());
}
