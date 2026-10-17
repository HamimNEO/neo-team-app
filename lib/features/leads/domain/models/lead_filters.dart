import 'lead.dart';
import 'lead_status.dart';

class LeadFilters {
  const LeadFilters(
      {this.statuses = const {},
      this.employees = const {},
      this.sources = const {},
      this.types = const {},
      this.priorities = const {}});

  final Set<String> statuses, employees, sources, types, priorities;

  bool get isActive => [statuses, employees, sources, types, priorities]
      .any((s) => s.isNotEmpty);

  static String key(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[_\-\s]+'), ' ');

  static String priority(String value) =>
      ['normal', 'medium'].contains(key(value)) ? 'medium' : key(value);

  bool matches(Lead lead) =>
      (statuses.isEmpty ||
          statuses
              .any((s) => LeadStatus.api(s) == LeadStatus.api(lead.status))) &&
      (employees.isEmpty ||
          employees.contains(lead.assignedEmployeeId ?? '')) &&
      (sources.isEmpty ||
          sources.any((s) => key(s) == key(lead.source ?? ''))) &&
      (types.isEmpty || types.any((s) => key(s) == key(lead.type))) &&
      (priorities.isEmpty ||
          priorities.any((s) => priority(s) == priority(lead.priority)));
}
