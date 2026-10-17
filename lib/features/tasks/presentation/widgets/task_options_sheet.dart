import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import 'task_assign_sheet.dart';
import 'task_completion_dialog.dart';
import '../../data/work_item_store.dart';
import '../../../team/data/employee_store.dart';

class TaskOptionsSheet extends StatelessWidget {
  final String taskId;
  final String taskTitle;

  const TaskOptionsSheet({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    Navigator.pop(context);
    try {
      await WorkItemStore.instance.update(taskId, {'status': newStatus});
      if (!context.mounted) return;
      final label = newStatus == 'in_progress'
          ? 'In Progress'
          : (newStatus == 'completed' ? 'Completed' : 'To Do');
      NecToast.show(
        context,
        message: 'Task moved to $label',
        type: NecToastType.success,
      );
    } catch (error) {
      if (context.mounted) {
        NecToast.show(
          context,
          message: WorkItemStore.messageFor(error),
          type: NecToastType.error,
        );
      }
    }
  }

  Future<void> _completeWithCelebration(BuildContext context) async {
    Navigator.pop(context);
    final confirmed = await TaskCompletionDialog.show(
      context,
      taskTitle: taskTitle,
      onConfirm: () async {
        await WorkItemStore.instance.update(taskId, {'status': 'completed'});
      },
    );
    if (confirmed == true && context.mounted) {
      NecToast.show(
        context,
        message: 'Task completed successfully! 🎉',
        type: NecToastType.success,
      );
    }
  }

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
            onPressed: () async {
              try {
                await WorkItemStore.instance
                    .update(taskId, {'status': 'cancelled'});
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!context.mounted) return;
                context.pop();
                NecToast.show(
                  context,
                  message: 'Task cancelled',
                  type: NecToastType.info,
                );
              } catch (error) {
                if (ctx.mounted) {
                  NecToast.show(ctx,
                      message: WorkItemStore.messageFor(error),
                      type: NecToastType.error);
                }
              }
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
        selectedAssignee:
            WorkItemStore.instance.byId(taskId)?.assigneeName ?? 'None',
        onSelected: (newAssignee) async {
          try {
            final employee = EmployeeStore.instance.employees
                .where((e) => e.name == newAssignee)
                .firstOrNull;
            await WorkItemStore.instance.update(taskId, {
              'assignee_employee_id': employee == null
                  ? null
                  : int.tryParse(employee.backendId ?? '')
            });
            if (context.mounted) {
              NecToast.show(context,
                  message: 'Task reassigned to $newAssignee',
                  type: NecToastType.success);
            }
          } catch (error) {
            if (context.mounted) {
              NecToast.show(context,
                  message: WorkItemStore.messageFor(error),
                  type: NecToastType.error);
            }
          }
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
            Builder(
              builder: (ctx) {
                final task = WorkItemStore.instance.byId(taskId);
                final status = task?.status ?? 'to_do';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status != 'in_progress')
                      InkWell(
                        onTap: () => _updateStatus(context, 'in_progress'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.flame_fill,
                                  size: 18, color: Color(0xFFF59E0B)),
                              SizedBox(width: 8),
                              Text(
                                'Start Task (In Progress)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (status != 'to_do') ...[
                      Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.3)),
                      InkWell(
                        onTap: () => _updateStatus(context, 'to_do'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.circle,
                                  size: 18, color: nec.brand),
                              const SizedBox(width: 8),
                              Text(
                                'Move to To Do',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: nec.brand,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (status != 'completed') ...[
                      Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.3)),
                      InkWell(
                        onTap: () => _completeWithCelebration(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.checkmark_seal_fill,
                                  size: 18, color: AppColors.success),
                              SizedBox(width: 8),
                              Text(
                                'Mark as Done',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            if (StaffAccessStore.instance.allows(StaffPermission.editTask)) ...[
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
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
            ],
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
