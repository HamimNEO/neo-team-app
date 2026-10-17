import 'dart:convert';

class WorkItem {
  final Map<String, dynamic> metadata;
  final String id;
  final String type;
  final String? leadId;
  final String? assigneeEmployeeId;
  final String title;
  final String status;
  final String priority;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? result;
  final String? details;
  final String? leadName;
  final String? leadLocation;
  final String? assigneeName;
  final String? assigneeDesignation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkItem({
    this.metadata = const {},
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.priority,
    this.leadId,
    this.assigneeEmployeeId,
    this.scheduledAt,
    this.completedAt,
    this.result,
    this.details,
    this.leadName,
    this.leadLocation,
    this.assigneeName,
    this.assigneeDesignation,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted =>
      status.toLowerCase() == 'completed' || status.toLowerCase() == 'done';

  static Object? _decodeDetails(Object? value) {
    for (var depth = 0; depth < 3 && value is String; depth++) {
      final text = value.trim();
      if (!text.startsWith('{') &&
          !text.startsWith('[') &&
          !text.startsWith('"')) {
        break;
      }
      try {
        value = jsonDecode(text);
      } on FormatException {
        break;
      }
    }
    return value;
  }

  static String? descriptionFrom(Object? value, [int depth = 0]) {
    if (depth > 5) return null;
    final decoded = _decodeDetails(value);
    if (decoded is String) return decoded.isEmpty ? null : decoded;
    if (decoded is Map) {
      for (final key in ['description', 'details', 'body', 'text']) {
        final text = descriptionFrom(decoded[key], depth + 1);
        if (text != null) return text;
      }
    }
    return null;
  }

  String get description =>
      descriptionFrom(details) ??
      descriptionFrom(metadata['description']) ??
      '';

  Map<String, dynamic> toJson() => {
        'metadata': metadata,
        'id': id,
        'type': type,
        'lead_id': leadId,
        'assignee_employee_id': assigneeEmployeeId,
        'title': title,
        'status': status,
        'priority': priority,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'result': result,
        'details': details,
        'lead_name': leadName,
        'lead_location': leadLocation,
        'assignee_name': assigneeName,
        'assignee_designation': assigneeDesignation,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory WorkItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    Map part(String key) => json[key] is Map ? json[key] as Map : {};
    final lead = part('lead'),
        assignee = part('assignee'),
        scheduled = part('scheduled');
    final rawId = json['assignee_employee_id'] ?? assignee['id'];
    final ownerId = rawId == null
        ? null
        : rawId.toString().startsWith('api_emp_')
            ? rawId.toString()
            : 'api_emp_$rawId';
    final details = _decodeDetails(json['details']);
    return WorkItem(
      metadata: {
        ...part('metadata'),
        if (details is Map) ...Map<String, dynamic>.from(details),
        for (final key in [
          'method',
          'purpose',
          'location',
          'category',
          'send_auto_sms',
          'contact_person',
          'actions',
          'journey',
          'report',
          'related_to',
          'related_reference'
        ])
          if (json.containsKey(key)) key: json[key]
      },
      id: json['id'].toString(),
      type: json['type']?.toString() ?? 'task',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'to_do',
      priority: json['priority']?.toString() ?? 'medium',
      leadId: (json['lead_id'] ?? lead['id'])?.toString(),
      assigneeEmployeeId: ownerId,
      scheduledAt: parseDate(json['scheduled_at'] ?? scheduled['at']),
      completedAt: parseDate(json['completed_at']),
      result: json['result']?.toString(),
      details: descriptionFrom(json['description']) ?? descriptionFrom(details),
      leadName: (json['lead_name'] ?? lead['name'])?.toString(),
      leadLocation: (json['lead_location'] ?? lead['location'])?.toString(),
      assigneeName: (json['assignee_name'] ?? assignee['name'])?.toString(),
      assigneeDesignation:
          (json['assignee_designation'] ?? assignee['designation'])?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'type': type,
      'title': title,
      if (leadId != null && leadId!.isNotEmpty)
        'lead_id': int.tryParse(leadId!) ?? leadId,
      if (assigneeEmployeeId != null && assigneeEmployeeId!.isNotEmpty)
        'assignee_employee_id':
            int.tryParse(assigneeEmployeeId!.replaceFirst('api_emp_', '')) ??
                assigneeEmployeeId!.replaceFirst('api_emp_', ''),
      'priority': priority.toLowerCase(),
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (details != null && details!.isNotEmpty) 'details': details,
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'title': title,
      'status': status,
      'priority': priority.toLowerCase(),
      if (result != null) 'result': result,
      if (details != null) 'details': details,
      if (assigneeEmployeeId != null && assigneeEmployeeId!.isNotEmpty)
        'assignee_employee_id':
            int.tryParse(assigneeEmployeeId!.replaceFirst('api_emp_', '')) ??
                assigneeEmployeeId!.replaceFirst('api_emp_', ''),
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    };
  }
}
