enum LunchStatus {
  receiving('Taking lunch'),
  skipped('Skipping lunch'),
  offDay('Day off'),
  leave('On leave'),
  notIncluded('Not scheduled'),
  inactive('Inactive');

  final String label;

  const LunchStatus(this.label);

  bool get available => this == receiving || this == skipped;
}

class LunchPreference {
  final String employeeId;
  final String day;
  final bool takeLunch;
  final String actorId;
  final DateTime updatedAt;
  final String mealPreference;
  final String? note, serverStatus;
  final bool? canChange;

  const LunchPreference(
      {required this.employeeId,
      required this.day,
      required this.takeLunch,
      required this.actorId,
      required this.updatedAt,
      this.mealPreference = 'regular',
      this.note,
      this.serverStatus,
      this.canChange});

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'day': day,
        'takeLunch': takeLunch,
        'actorId': actorId,
        'updatedAt': updatedAt.toIso8601String(),
        'mealPreference': mealPreference,
        'note': note,
        'serverStatus': serverStatus,
        'canChange': canChange,
      };

  factory LunchPreference.fromJson(Map<String, dynamic> json) =>
      LunchPreference(
          employeeId: json['employeeId'] as String,
          day: json['day'] as String,
          takeLunch: json['takeLunch'] as bool,
          actorId: json['actorId'] as String,
          updatedAt: DateTime.parse(json['updatedAt'] as String),
          mealPreference: json['mealPreference']?.toString() ?? 'regular',
          note: json['note'] as String?,
          serverStatus: json['serverStatus'] as String?,
          canChange: json['canChange'] as bool?);
}
