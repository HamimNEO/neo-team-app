class Visit {
  final String id;
  final String leadName;
  final String leadId;
  final String location;
  final String purpose;
  final String dateText;
  final String timeText;
  final String assigneeName;
  final String assigneeInitials;
  String status;
  String statusGroup;
  final String? resultTag;

  Visit({
    required this.id,
    required this.leadName,
    this.leadId = 'lead_1',
    required this.location,
    required this.purpose,
    required this.dateText,
    required this.timeText,
    required this.assigneeName,
    required this.assigneeInitials,
    required this.status,
    required this.statusGroup,
    this.resultTag,
  });
}
