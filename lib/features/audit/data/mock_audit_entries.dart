import '../domain/models/audit_entry.dart';

final List<AuditEntry> mockAuditEntries = List.unmodifiable(_createEntries());

AuditEntry? findAuditEntry(String id) {
  for (final entry in mockAuditEntries) {
    if (entry.id == id) return entry;
  }
  return null;
}

List<AuditEntry> _createEntries() {
  final now = DateTime.now();
  DateTime at(int daysAgo, int hour, int minute) {
    return DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
  }

  return [
    AuditEntry(
      id: 'role-updated',
      action: 'Role updated',
      actor: 'Rahul Sharma',
      entity: 'Sales Manager',
      entityType: 'Role',
      category: AuditCategory.access,
      timestamp: at(0, 15, 42),
      highImpact: true,
      changes: const [
        AuditChange(field: 'Lead Access', before: 'Team', after: 'All'),
        AuditChange(field: 'Assign Lead', before: 'Off', after: 'On'),
      ],
    ),
    AuditEntry(
      id: 'employee-deactivated',
      action: 'Employee deactivated',
      actor: 'Priya Nair',
      entity: 'Omar Hassan',
      entityType: 'Employee',
      category: AuditCategory.employees,
      timestamp: at(0, 13, 15),
      highImpact: true,
      changes: const [
        AuditChange(
            field: 'Account Status', before: 'Active', after: 'Inactive'),
        AuditChange(field: 'Login Access', before: 'On', after: 'Off'),
      ],
    ),
    AuditEntry(
      id: 'lead-settings-updated',
      action: 'Lead Settings updated',
      actor: 'Rahul Sharma',
      entity: 'Lead Statuses',
      entityType: 'Configuration',
      category: AuditCategory.leads,
      timestamp: at(0, 11, 30),
      changes: const [
        AuditChange(
            field: 'Status Label', before: 'Negotiating', after: 'Negotiation'),
        AuditChange(field: 'Lost Reason Required', before: 'Off', after: 'On'),
      ],
    ),
    AuditEntry(
      id: 'module-disabled',
      action: 'Module disabled',
      actor: 'Rahul Sharma',
      entity: 'Visits',
      entityType: 'Module',
      category: AuditCategory.modules,
      timestamp: at(0, 10, 5),
      highImpact: true,
      changes: const [
        AuditChange(
            field: 'Module Status', before: 'Enabled', after: 'Disabled'),
      ],
    ),
    AuditEntry(
      id: 'employee-role-changed',
      action: 'Employee role changed',
      actor: 'Priya Nair',
      entity: 'Shahina Akter',
      entityType: 'Employee',
      category: AuditCategory.access,
      timestamp: at(1, 16, 55),
      highImpact: true,
      changes: const [
        AuditChange(
            field: 'Role', before: 'Sales Agent', after: 'Sales Manager'),
        AuditChange(field: 'Lead Access', before: 'Own', after: 'Team'),
      ],
    ),
    AuditEntry(
      id: 'department-created',
      action: 'Department created',
      actor: 'Rahul Sharma',
      entity: 'Customer Success',
      entityType: 'Department',
      category: AuditCategory.employees,
      timestamp: at(1, 14, 20),
      changes: const [
        AuditChange(
            field: 'Department Name', before: '—', after: 'Customer Success'),
        AuditChange(field: 'Department Head', before: '—', after: 'Priya Nair'),
      ],
    ),
    AuditEntry(
      id: 'notification-settings-updated',
      action: 'Notification Settings updated',
      actor: 'Priya Nair',
      entity: 'System Notifications',
      entityType: 'Configuration',
      category: AuditCategory.settings,
      timestamp: at(1, 10, 10),
      changes: const [
        AuditChange(field: 'Assignment Alerts', before: 'Off', after: 'On'),
        AuditChange(field: 'Overdue Reminders', before: 'Off', after: 'On'),
      ],
    ),
    AuditEntry(
      id: 'session-revoked',
      action: 'Session revoked',
      actor: 'Rahul Sharma',
      entity: 'Omar Hassan',
      entityType: 'Session',
      category: AuditCategory.system,
      timestamp: at(2, 17, 30),
      highImpact: true,
      changes: const [
        AuditChange(
            field: 'Session Status', before: 'Active', after: 'Revoked'),
      ],
    ),
    AuditEntry(
      id: 'lead-source-added',
      action: 'Lead source added',
      actor: 'Priya Nair',
      entity: 'Instagram',
      entityType: 'Lead Source',
      category: AuditCategory.leads,
      timestamp: at(2, 12, 45),
      changes: const [
        AuditChange(field: 'Source Name', before: '—', after: 'Instagram'),
        AuditChange(field: 'Status', before: '—', after: 'Enabled'),
      ],
    ),
  ];
}
