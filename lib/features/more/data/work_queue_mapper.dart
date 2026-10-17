import 'package:intl/intl.dart';
import '../../../core/services/demo_session.dart';
import '../../leads/data/lead_store.dart';
import '../../tasks/domain/models/work_item.dart';
import '../../team/domain/models/employee.dart';
import '../domain/models/follow_up.dart';
import '../domain/models/visit.dart';
import '../domain/models/issue.dart';

class WorkQueueMapper {
  static String date(DateTime? value) => value == null
      ? 'Not scheduled'
      : DateFormat('MMM d, yyyy').format(value.toLocal());

  static String time(DateTime? value) =>
      value == null ? '' : DateFormat.jm().format(value.toLocal());

  static String group(WorkItem item) {
    if (item.isCompleted) return 'Done';
    if (item.status == 'cancelled') return 'Cancelled';
    final d = item.scheduledAt?.toLocal(), now = DateTime.now();
    if (d == null) return 'Unscheduled';
    if (d.isBefore(now)) return 'Overdue';
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (DateTime(d.year, d.month, d.day) == tomorrow) return 'Tomorrow';
    return 'This Week';
  }

  static FollowUp followUp(WorkItem item) => FollowUp(
        id: item.id,
        leadId: item.leadId ?? '',
        leadName: item.leadName ?? item.title,
        purpose: item.metadata['purpose']?.toString() ?? item.title,
        method: switch (item.metadata['method']?.toString().toLowerCase()) {
          'call' || 'phone' => 'Call',
          'whatsapp' => 'WhatsApp',
          'email' => 'Email',
          'meeting' => 'Meeting',
          _ => 'Other',
        },
        dateText: date(item.scheduledAt),
        timeText: time(item.scheduledAt),
        assigneeName: item.assigneeName ?? 'Unassigned',
        assigneeInitials: Employee.initialsFor(item.assigneeName ?? ''),
        statusGroup: group(item),
        isCompleted: item.isCompleted,
        lateHours: item.scheduledAt != null && group(item) == 'Overdue'
            ? '${DateTime.now().difference(item.scheduledAt!).inHours}h'
            : null,
        resultTag: item.result,
        isAutoSmsEnabled: item.metadata['send_auto_sms'] == true,
        autoSmsStatus:
            item.metadata['send_auto_sms'] == true ? 'Enabled' : 'Disabled',
        autoSmsRecipientPhone:
            LeadStore.instance.byId(item.leadId ?? '')?.phone,
      );

  static Visit visit(WorkItem item) => Visit(
        id: item.id,
        leadId: item.leadId ?? '',
        leadName: item.leadName ?? item.title,
        location:
            item.metadata['location']?.toString() ?? item.leadLocation ?? '',
        purpose: item.metadata['purpose']?.toString() ?? item.title,
        dateText: date(item.scheduledAt),
        timeText: time(item.scheduledAt),
        assigneeName: item.assigneeName ?? 'Unassigned',
        assigneeInitials: Employee.initialsFor(item.assigneeName ?? ''),
        status: item.isCompleted
            ? 'Completed'
            : item.status == 'cancelled'
                ? 'Cancelled'
                : item.status == 'arrived'
                    ? 'Arrived'
                    : 'Scheduled',
        statusGroup: item.isCompleted
            ? 'Completed'
            : group(item) == 'Unscheduled'
                ? 'This Week'
                : group(item),
        resultTag: item.result,
      );

  static Issue issue(WorkItem item) => Issue(
        id: item.id,
        title: item.title,
        description:
            item.details ?? item.metadata['description']?.toString() ?? '',
        priority: item.priority == 'medium' ||
                item.priority == 'normal' ||
                item.priority.isEmpty
            ? 'Normal'
            : '${item.priority[0].toUpperCase()}${item.priority.substring(1)}',
        status: item.isCompleted || item.status == 'resolved'
            ? 'Resolved'
            : item.status == 'in_progress'
                ? 'In Progress'
                : 'Reported',
        category: item.metadata['category']?.toString() ?? '',
        project: item.leadName ?? '',
        assigneeName: item.assigneeName,
        assigneeInitials: Employee.initialsFor(item.assigneeName ?? ''),
        date: date(item.createdAt),
        scopeMine: item.assigneeEmployeeId == DemoSession.instance.employeeId,
        scopeTeam: true,
        hasRedDot: ['urgent', 'high'].contains(item.priority),
      );

  static DateTime scheduled(String dateText, String timeText) {
    final now = DateTime.now();
    DateTime? d = switch (dateText.toLowerCase()) {
      'today' => now,
      'tomorrow' => DateTime(now.year, now.month, now.day + 1),
      'next week' => DateTime(now.year, now.month, now.day + 7),
      _ => DateTime.tryParse(dateText),
    };
    for (final format in ['MMM d, yyyy', 'd/M/yyyy', 'MMM d']) {
      if (d != null) break;
      try {
        d = DateFormat(format).parseStrict(dateText);
      } catch (_) {}
    }
    if (d == null) throw const FormatException('Choose a valid schedule date.');
    DateTime? t;
    for (final format in ['h:mm a', 'HH:mm']) {
      try {
        t = DateFormat(format).parseStrict(timeText);
        break;
      } catch (_) {}
    }
    if (t == null) throw const FormatException('Choose a valid schedule time.');
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }
}
