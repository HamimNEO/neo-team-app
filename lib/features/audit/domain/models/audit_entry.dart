enum AuditCategory {
  access('Access'),
  employees('Employees'),
  leads('Leads'),
  modules('Modules'),
  settings('Settings'),
  system('System');

  final String label;

  const AuditCategory(this.label);
}

class AuditChange {
  final String field;
  final String before;
  final String after;

  const AuditChange({
    required this.field,
    required this.before,
    required this.after,
  });
}

class AuditEntry {
  final String id;
  final String action;
  final String actor;
  final String entity;
  final String entityType;
  final AuditCategory category;
  final DateTime timestamp;
  final bool highImpact;
  final List<AuditChange> changes;

  const AuditEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.entity,
    required this.entityType,
    required this.category,
    required this.timestamp,
    this.highImpact = false,
    this.changes = const [],
  });

  String get initials => actor
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  bool matchesSearch(String query) {
    final searchable =
        '$actor $entity $entityType $action ${category.label}'.toLowerCase();
    return query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .every(searchable.contains);
  }
}
