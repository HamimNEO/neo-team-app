import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import 'task_assign_sheet.dart';

class TaskOptionsSheet extends StatelessWidget {
  final String taskId;
  final String taskTitle;

  const TaskOptionsSheet({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  void _confirmCancel(BuildContext context) {
    if (!DemoSession.instance.isAdmin) {
      return;
    }
    Navigator.pop(context);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Cancel Task?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'This task will be cancelled and removed from active lists.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
              NecToast.show(
                context,
                message: 'Task cancelled',
                type: NecToastType.info,
              );
            },
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );
  }

  void _openReassignSheet(BuildContext context) {
    if (!DemoSession.instance.isAdmin) {
      return;
    }
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskAssignSheet(
        selectedAssignee: 'Most. Shahina Akter',
        onSelected: (newAssignee) {
          NecToast.show(
            context,
            message: 'Task reassigned to $newAssignee',
            type: NecToastType.success,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: nec.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (StaffAccessStore.instance.allows(StaffPermission.editTask))
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/edit-task/$taskId');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Edit Task',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: nec.brand,
                    ),
                  ),
                ),
              ),
            if (DemoSession.instance.isAdmin) ...[
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              InkWell(
                onTap: () => _openReassignSheet(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Reassign',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              InkWell(
                onTap: () => _confirmCancel(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    'Cancel Task',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
