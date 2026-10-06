import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_badge.dart';
import '../../domain/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: nec.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                    ),
                    PriorityBadge(priority: task.priority),
                  ],
                ),
                if (task.relatedLeadName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.relatedLeadName!,
                    style: TextStyle(fontSize: 12, color: nec.brand),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 13,
                      color: nec.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.assignedTo ?? 'Unassigned',
                      style: TextStyle(fontSize: 12, color: nec.textTertiary),
                    ),
                    const Spacer(),
                    TaskStatusBadge(status: task.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
