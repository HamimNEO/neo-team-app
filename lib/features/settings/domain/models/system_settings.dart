enum OrganizationTimezone {
  dhaka('Asia/Dhaka', 'GMT+6'),
  kolkata('Asia/Kolkata', 'GMT+5:30'),
  kathmandu('Asia/Kathmandu', 'GMT+5:45'),
  dubai('Asia/Dubai', 'GMT+4'),
  singapore('Asia/Singapore', 'GMT+8'),
  tokyo('Asia/Tokyo', 'GMT+9'),
  utc('UTC', 'GMT+0');

  final String label;
  final String offset;

  const OrganizationTimezone(this.label, this.offset);
}

enum OrganizationDateFormat {
  dayFirst('DD/MM/YYYY'),
  monthFirst('MM/DD/YYYY'),
  yearFirst('YYYY-MM-DD');

  final String label;

  const OrganizationDateFormat(this.label);
}

class SystemSettings {
  static const leadPriorities = ['Low', 'Normal', 'High', 'Urgent'];

  final String organizationName;
  final String primaryWorkEmail;
  final String defaultLeadPriority;
  final bool autoAssignLeads;
  final bool taskReviewStage;
  final bool issueTestingStage;
  final bool requireLostReason;
  final OrganizationTimezone timezone;
  final OrganizationDateFormat dateFormat;

  const SystemSettings({
    this.organizationName = 'NEONECY',
    this.primaryWorkEmail = 'admin@neonecy.com',
    this.defaultLeadPriority = 'Normal',
    this.autoAssignLeads = false,
    this.taskReviewStage = true,
    this.issueTestingStage = true,
    this.requireLostReason = false,
    this.timezone = OrganizationTimezone.dhaka,
    this.dateFormat = OrganizationDateFormat.dayFirst,
  });

  SystemSettings copyWith({
    String? organizationName,
    String? primaryWorkEmail,
    String? defaultLeadPriority,
    bool? autoAssignLeads,
    bool? taskReviewStage,
    bool? issueTestingStage,
    bool? requireLostReason,
    OrganizationTimezone? timezone,
    OrganizationDateFormat? dateFormat,
  }) =>
      SystemSettings(
        organizationName: organizationName ?? this.organizationName,
        primaryWorkEmail: primaryWorkEmail ?? this.primaryWorkEmail,
        defaultLeadPriority: defaultLeadPriority ?? this.defaultLeadPriority,
        autoAssignLeads: autoAssignLeads ?? this.autoAssignLeads,
        taskReviewStage: taskReviewStage ?? this.taskReviewStage,
        issueTestingStage: issueTestingStage ?? this.issueTestingStage,
        requireLostReason: requireLostReason ?? this.requireLostReason,
        timezone: timezone ?? this.timezone,
        dateFormat: dateFormat ?? this.dateFormat,
      );

  Map<String, Object> toJson() => {
        'organizationName': organizationName,
        'primaryWorkEmail': primaryWorkEmail,
        'defaultLeadPriority': defaultLeadPriority,
        'autoAssignLeads': autoAssignLeads,
        'taskReviewStage': taskReviewStage,
        'issueTestingStage': issueTestingStage,
        'requireLostReason': requireLostReason,
        'timezone': timezone.name,
        'dateFormat': dateFormat.name,
      };

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    const defaults = SystemSettings();
    String text(String key, String fallback) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty
          ? value.trim()
          : fallback;
    }

    bool flag(String key, bool fallback) =>
        json[key] is bool ? json[key] as bool : fallback;
    final priority = text('defaultLeadPriority', defaults.defaultLeadPriority);

    return SystemSettings(
      organizationName: text('organizationName', defaults.organizationName),
      primaryWorkEmail: text('primaryWorkEmail', defaults.primaryWorkEmail),
      defaultLeadPriority: leadPriorities.contains(priority)
          ? priority
          : defaults.defaultLeadPriority,
      autoAssignLeads: flag('autoAssignLeads', defaults.autoAssignLeads),
      taskReviewStage: flag('taskReviewStage', defaults.taskReviewStage),
      issueTestingStage: flag('issueTestingStage', defaults.issueTestingStage),
      requireLostReason: flag('requireLostReason', defaults.requireLostReason),
      timezone: OrganizationTimezone.values.firstWhere(
        (value) => value.name == json['timezone'],
        orElse: () => defaults.timezone,
      ),
      dateFormat: OrganizationDateFormat.values.firstWhere(
        (value) => value.name == json['dateFormat'],
        orElse: () => defaults.dateFormat,
      ),
    );
  }
}
