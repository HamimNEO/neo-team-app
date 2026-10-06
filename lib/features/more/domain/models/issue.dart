class Issue {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String category;
  final String project;
  final String? assigneeName;
  final String? assigneeInitials;
  final String date;
  final bool scopeMine;
  final bool scopeTeam;
  final bool hasRedDot;

  const Issue({
    required this.id,
    required this.title,
    this.description = '',
    required this.priority,
    required this.status,
    required this.category,
    required this.project,
    this.assigneeName,
    this.assigneeInitials,
    required this.date,
    this.scopeMine = false,
    this.scopeTeam = true,
    this.hasRedDot = false,
  });
}
