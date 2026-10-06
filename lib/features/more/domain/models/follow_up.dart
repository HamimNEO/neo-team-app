class FollowUp {
  final String id;
  final String leadName;
  final String leadId;
  final String purpose;
  final String method;
  final String dateText;
  final String timeText;
  final String assigneeName;
  final String assigneeInitials;
  String statusGroup;
  final String? lateHours;
  String? resultTag;
  bool isCompleted;
  bool isAutoSmsEnabled;
  String? autoSmsStatus;
  String? autoSmsRecipientPhone;

  FollowUp({
    required this.id,
    required this.leadName,
    this.leadId = 'lead_1',
    required this.purpose,
    required this.method,
    required this.dateText,
    required this.timeText,
    required this.assigneeName,
    required this.assigneeInitials,
    required this.statusGroup,
    this.lateHours,
    this.resultTag,
    this.isCompleted = false,
    this.isAutoSmsEnabled = true,
    this.autoSmsStatus = 'Scheduled',
    this.autoSmsRecipientPhone = '+880 1711-222222',
  });
}
