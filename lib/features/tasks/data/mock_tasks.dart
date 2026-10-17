import '../domain/models/task.dart';
import 'work_item_store.dart';

List<Task> get mockTasks {
  final items = WorkItemStore.instance.tasks;
  return items
      .map((w) => Task(
            id: w.id,
            title: w.title,
            status: w.status.toLowerCase() == 'completed'
                ? 'Completed'
                : (w.status.toLowerCase() == 'in_progress'
                    ? 'In Progress'
                    : 'To Do'),
            priority: w.priority.toLowerCase() == 'high'
                ? 'High'
                : (w.priority.toLowerCase() == 'low' ? 'Low' : 'Normal'),
            relatedLeadName: w.leadName,
            relatedLeadId: w.leadId,
            assignedTo: w.assigneeName,
            dueDate: w.scheduledAt,
            notes: w.details,
          ))
      .toList();
}
