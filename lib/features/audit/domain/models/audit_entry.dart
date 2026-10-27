import 'dart:convert';

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
  final String? ipAddress, userAgent, eventType, actorId;

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
    this.ipAddress,
    this.userAgent,
    this.eventType,
    this.actorId,
  });

  factory AuditEntry.fromApi(Map<String, dynamic> data) {
    final metadata = data['metadata'] is Map ? data['metadata'] as Map : {};
    final actor = data['actor'] is Map ? data['actor'] as Map : {};
    final event =
        data['event']?.toString() ?? data['event_type']?.toString() ?? '';
    final before = data['before'] ?? metadata['before'],
        after = data['after'] ?? metadata['after'];
    final changes = <AuditChange>[];
    if (before is Map || after is Map) {
      final old = before is Map ? before : {},
          current = after is Map ? after : {};
      for (final key in {...old.keys, ...current.keys}) {
        String value(Object? v) => v == null
            ? '—'
            : v is Map || v is List
                ? jsonEncode(v)
                : v.toString();
        if (value(old[key]) != value(current[key])) {
          changes.add(AuditChange(
              field: key.toString(),
              before: value(old[key]),
              after: value(current[key])));
        }
      }
    }
    final timestamp = DateTime.tryParse(data['created_at']?.toString() ?? '');
    if (data['id'] == null || timestamp == null) {
      throw const FormatException(
          'An audit record is missing its ID or timestamp.');
    }
    return AuditEntry(
        id: data['id'].toString(),
        action: data['description']?.toString() ??
            event.replaceAll('_', ' ').replaceAll('.', ' · '),
        actor: (data['actor_name'] ?? actor['name'])?.toString() ??
            'Unknown actor',
        entity: (data['entity_name'] ?? data['entity_id'])?.toString() ?? '',
        entityType: data['entity_type']?.toString() ?? '',
        category: event.contains('employee')
            ? AuditCategory.employees
            : event.contains('role') || event.contains('access')
                ? AuditCategory.access
                : event.contains('lead')
                    ? AuditCategory.leads
                    : event.contains('module')
                        ? AuditCategory.modules
                        : event.contains('setting')
                            ? AuditCategory.settings
                            : AuditCategory.system,
        timestamp: timestamp,
        highImpact: data['high_impact'] == true,
        changes: changes,
        eventType: event,
        actorId: (data['actor_user_id'] ?? actor['id'])?.toString(),
        ipAddress:
            (data['ip_address'] ?? metadata['ip_address'] ?? metadata['ip'])
                ?.toString(),
        userAgent: (data['user_agent'] ?? metadata['user_agent'])?.toString());
  }

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
