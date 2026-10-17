import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../tasks/data/work_item_store.dart';
import '../../data/lead_store.dart';

class LeadWorkTab extends StatefulWidget {
  final String leadId;
  final Map<String, dynamic> work;

  const LeadWorkTab({
    super.key,
    required this.leadId,
    this.work = const {},
  });

  @override
  State<LeadWorkTab> createState() => _LeadWorkTabState();
}

class _LeadWorkTabState extends State<LeadWorkTab> {
  bool _busy = false;

  Widget _buildSectionHeader(BuildContext context, String title) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: nec.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _rescheduleItem(String id, bool isVisit) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
    );
    if (pickedTime == null || !mounted) return;

    final dateStr =
        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

    setState(() => _busy = true);
    try {
      if (isVisit) {
        await WorkItemStore.instance.rescheduleVisit(id, dateStr, timeStr);
      } else {
        await WorkItemStore.instance.rescheduleFollowUp(id, dateStr, timeStr);
      }
      await LeadStore.instance.fetchDetails(widget.leadId, force: true);
      if (mounted) {
        NecToast.show(context,
            message: 'Rescheduled to $dateStr at $timeStr',
            type: NecToastType.success);
      }
    } catch (_) {
      if (mounted) {
        NecToast.show(context,
            message: 'Failed to reschedule. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeFollowUp(String id) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Follow-Up'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter call summary or outcome notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final result = controller.text.trim();
              Navigator.pop(ctx);
              setState(() => _busy = true);
              try {
                await WorkItemStore.instance.completeFollowUp(
                  id,
                  result.isNotEmpty ? result : 'Follow-up completed.',
                );
                await LeadStore.instance
                    .fetchDetails(widget.leadId, force: true);
                if (mounted) {
                  NecToast.show(context,
                      message: 'Follow-up marked as completed',
                      type: NecToastType.success);
                }
              } catch (_) {
                if (mounted) {
                  NecToast.show(context,
                      message: 'Failed to complete follow-up.',
                      type: NecToastType.error);
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeVisit(String id) async {
    final outcomeController = TextEditingController();
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Visit Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: outcomeController,
              decoration: const InputDecoration(
                labelText: 'Outcome / Decision',
                hintText: 'e.g. Very Interested, Proposal requested',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Meeting Notes',
                hintText: 'Key points discussed...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _busy = true);
              try {
                await WorkItemStore.instance.completeVisitReport(id, {
                  'outcome': outcomeController.text.trim().isNotEmpty
                      ? outcomeController.text.trim()
                      : 'Completed',
                  'notes': notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : 'Site visit finished.',
                });
                await LeadStore.instance
                    .fetchDetails(widget.leadId, force: true);
                if (mounted) {
                  NecToast.show(context,
                      message: 'Visit completed successfully',
                      type: NecToastType.success);
                }
              } catch (_) {
                if (mounted) {
                  NecToast.show(context,
                      message: 'Failed to complete visit report.',
                      type: NecToastType.error);
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final followups =
        (widget.work['followups'] as List? ?? []).whereType<Map>().toList();
    final visits =
        (widget.work['visits'] as List? ?? []).whereType<Map>().toList();
    final tasks =
        (widget.work['tasks'] as List? ?? []).whereType<Map>().toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'FOLLOW-UP'),
          if (followups.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No follow-ups scheduled for this lead.',
                style: TextStyle(fontSize: 14, color: nec.textTertiary),
              ),
            )
          else
            ...followups.map((item) {
              final id = item['id'].toString();
              final title = item['title']?.toString() ?? 'Follow-up Call';
              final time = item['scheduled_at']?.toString() ?? 'Scheduled';
              final notes = item['notes']?.toString() ?? '';
              final assigned = item['assigned_to']?['name']?.toString() ??
                  item['assignee_name']?.toString() ??
                  'Assigned';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Follow-up',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(time,
                        style:
                            TextStyle(fontSize: 13, color: nec.textSecondary)),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(notes,
                          style:
                              TextStyle(fontSize: 13, color: nec.textTertiary)),
                    ],
                    const SizedBox(height: 4),
                    Text('Assigned: $assigned',
                        style:
                            TextStyle(fontSize: 12, color: nec.textTertiary)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed:
                                  _busy ? null : () => _completeFollowUp(id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.success.withValues(alpha: 0.15),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Complete',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _rescheduleItem(id, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: nec.bg,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Reschedule',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          _buildSectionHeader(context, 'VISIT'),
          if (visits.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No visits scheduled for this lead.',
                style: TextStyle(fontSize: 14, color: nec.textTertiary),
              ),
            )
          else
            ...visits.map((item) {
              final id = item['id'].toString();
              final title = item['title']?.toString() ?? 'Onsite Visit';
              final time = item['scheduled_at']?.toString() ?? 'Scheduled';
              final location = item['location']?.toString() ?? '';
              final assigned = item['assigned_to']?['name']?.toString() ??
                  item['assignee_name']?.toString() ??
                  'Assigned';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0D9488).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'VISIT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(time,
                        style:
                            TextStyle(fontSize: 13, color: nec.textSecondary)),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(location,
                          style:
                              TextStyle(fontSize: 13, color: nec.textTertiary)),
                    ],
                    const SizedBox(height: 4),
                    Text('Assigned: $assigned',
                        style:
                            TextStyle(fontSize: 12, color: nec.textTertiary)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed:
                                  _busy ? null : () => _completeVisit(id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: nec.brand,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Complete Visit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _rescheduleItem(id, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: nec.bg,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Reschedule',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, 'TASKS'),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.push('/create-task'),
                child: Text(
                  '+ Task',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: nec.brand,
                  ),
                ),
              ),
            ],
          ),
          if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No pending tasks for this lead.',
                style: TextStyle(fontSize: 14, color: nec.textTertiary),
              ),
            )
          else
            Material(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(tasks.length, (index) {
                  final task = tasks[index];
                  final isLast = index == tasks.length - 1;
                  final taskId = task['id'].toString();
                  final taskTitle = task['title']?.toString() ?? 'Task';
                  final isCompleted =
                      task['status']?.toString().toLowerCase() == 'completed';

                  return Column(
                    children: [
                      ListTile(
                        leading: Checkbox(
                          value: isCompleted,
                          activeColor: nec.brand,
                          onChanged: (val) async {
                            final newStatus =
                                (val == true) ? 'completed' : 'to_do';
                            await WorkItemStore.instance.update(
                              taskId,
                              {'status': newStatus},
                            );
                            await LeadStore.instance
                                .fetchDetails(widget.leadId, force: true);
                            if (mounted) setState(() {});
                          },
                        ),
                        title: Text(
                          taskTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? nec.textTertiary
                                : nec.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          task['due_date']?.toString() ?? 'No due date',
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                          indent: 56,
                        ),
                    ],
                  );
                }),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
