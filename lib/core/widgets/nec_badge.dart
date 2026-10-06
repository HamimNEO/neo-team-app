import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LeadStatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const LeadStatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.leadStatusColor(status);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(status,
              style: TextStyle(
                  fontSize: small ? 10.0 : 11.0,
                  fontWeight: FontWeight.w600,
                  color: c)),
        ]));
  }
}

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  Color get _c {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'low':
        return AppColors.neutral;
      default:
        return AppColors.brandLight;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: _c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5)),
      child: Text(priority,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _c)));
}

class TaskStatusBadge extends StatelessWidget {
  final String status;

  const TaskStatusBadge({super.key, required this.status});

  Color get _c {
    switch (status) {
      case 'In Progress':
        return AppColors.taskInProgress;
      case 'Review':
        return AppColors.taskReview;
      case 'Completed':
        return AppColors.taskCompleted;
      default:
        return AppColors.taskTodo;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: _c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _c)));
}
