import '../domain/models/task.dart';

final List<Task> mockTasks = [
  Task(
    id: 't-001',
    title: 'Send Enterprise proposal',
    status: 'To Do',
    priority: 'High',
    relatedLeadName: 'Sea Pearl Resort',
    assignedTo: 'Shahina',
    dueDate: DateTime.now(),
  ),
  Task(
    id: 't-002',
    title: 'Demo call preparation',
    status: 'In Progress',
    priority: 'High',
    relatedLeadName: 'Royal Tulip Sea Pearl',
    assignedTo: 'Shahina',
    dueDate: DateTime.now(),
  ),
  Task(
    id: 't-003',
    title: 'Update CRM records',
    status: 'To Do',
    priority: 'Normal',
    assignedTo: 'Rafiq',
    dueDate: DateTime.now().add(const Duration(days: 1)),
  ),
  Task(
    id: 't-004',
    title: 'Follow up with Blue Wave',
    status: 'To Do',
    priority: 'Normal',
    relatedLeadName: 'Blue Wave Resort',
    assignedTo: 'Rafiq',
    dueDate: DateTime.now().add(const Duration(days: 1)),
  ),
  const Task(
    id: 't-005',
    title: 'Prepare visit report',
    status: 'Completed',
    priority: 'Low',
    relatedLeadName: 'Ocean Paradise Hotel',
    assignedTo: 'Shahina',
  ),
];
