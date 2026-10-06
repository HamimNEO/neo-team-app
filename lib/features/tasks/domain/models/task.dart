class Task {
  final String id;
  final String title;
  final String status;
  final String priority;
  final String? relatedLeadId;
  final String? relatedLeadName;
  final String? assignedTo;
  final String? notes;
  final DateTime? dueDate;

  const Task({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.relatedLeadId,
    this.relatedLeadName,
    this.assignedTo,
    this.dueDate,
    this.notes,
  });
}
