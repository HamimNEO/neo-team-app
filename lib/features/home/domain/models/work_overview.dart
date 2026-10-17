class WorkSummary {
  final int leads;
  final int newLeads;
  final int dueFollowups;
  final int todayVisits;
  final int openTasks;
  final int openIssues;

  const WorkSummary({
    this.leads = 0,
    this.newLeads = 0,
    this.dueFollowups = 0,
    this.todayVisits = 0,
    this.openTasks = 0,
    this.openIssues = 0,
  });

  factory WorkSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    return WorkSummary(
      leads: parseInt(json['leads'] ?? json['assigned_leads']),
      newLeads: parseInt(json['new_leads']),
      dueFollowups: parseInt(json['due_followups']),
      todayVisits: parseInt(json['today_visits']),
      openTasks: parseInt(json['open_tasks']),
      openIssues: parseInt(json['open_issues']),
    );
  }

  Map<String, dynamic> toJson() => {
        'leads': leads,
        'new_leads': newLeads,
        'due_followups': dueFollowups,
        'today_visits': todayVisits,
        'open_tasks': openTasks,
        'open_issues': openIssues,
      };
}

class WorkActivityItem {
  final int id;
  final String actorName;
  final String entityType;
  final int? entityId;
  final String event;
  final String description;
  final DateTime? createdAt;

  const WorkActivityItem({
    required this.id,
    required this.actorName,
    required this.entityType,
    this.entityId,
    required this.event,
    required this.description,
    this.createdAt,
  });

  factory WorkActivityItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    return WorkActivityItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      actorName: json['actor_name']?.toString() ?? 'System',
      entityType: json['entity_type']?.toString() ?? '',
      entityId: json['entity_id'] is int
          ? json['entity_id'] as int
          : int.tryParse(json['entity_id']?.toString() ?? ''),
      event: json['event']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'actor_name': actorName,
        'entity_type': entityType,
        'entity_id': entityId,
        'event': event,
        'description': description,
        'created_at': createdAt?.toIso8601String(),
      };
}

class WorkOverview {
  final WorkSummary summary;
  final List<Map<String, dynamic>> attention;
  final List<WorkActivityItem> recentActivity;
  final List<Map<String, dynamic>> today, leadsNeedingAction;

  const WorkOverview({
    this.summary = const WorkSummary(),
    this.attention = const [],
    this.recentActivity = const [],
    this.today = const [],
    this.leadsNeedingAction = const [],
  });

  factory WorkOverview.fromJson(Map<String, dynamic> json) {
    final summaryRaw = json['summary'];
    final attentionRaw = json['attention'];
    final activityRaw = json['recent_activity'];

    List<Map<String, dynamic>> rows(Object? raw) => raw is List
        ? raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
        : [];
    final todayRaw = json['today'];
    return WorkOverview(
      today: rows(todayRaw is Map
          ? (todayRaw['schedule'] ?? todayRaw['items'])
          : todayRaw),
      leadsNeedingAction: rows(json['leads_needing_action']),
      summary: summaryRaw is Map
          ? WorkSummary.fromJson(Map<String, dynamic>.from(summaryRaw))
          : const WorkSummary(),
      attention: attentionRaw is List
          ? attentionRaw
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList()
          : const [],
      recentActivity: activityRaw is List
          ? activityRaw
              .whereType<Map>()
              .map((m) =>
                  WorkActivityItem.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary.toJson(),
        'attention': attention,
        'today': {'schedule': today},
        'leads_needing_action': leadsNeedingAction,
        'recent_activity': recentActivity.map((a) => a.toJson()).toList(),
      };
}
