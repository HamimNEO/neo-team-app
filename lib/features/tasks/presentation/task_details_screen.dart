import '../../more/data/work_queue_mapper.dart';
import '../../team/domain/models/employee.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/work_item_store.dart';
import '../domain/models/work_item.dart';
import 'widgets/task_completion_dialog.dart';
import 'widgets/task_options_sheet.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final _commentController = TextEditingController();

  List<Map<String, String>> _comments = [];

  @override
  void initState() {
    super.initState();
    WorkItemStore.instance.addListener(_refresh);
    WorkItemStore.instance.fetchDetails(widget.taskId).catchError((error) {
      if (mounted) {
        NecToast.show(context,
            message: WorkItemStore.messageFor(error), type: NecToastType.error);
      }
      return <String, dynamic>{};
    });
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    final raw = WorkItemStore.instance.detailsFor(widget.taskId)?['comments'];
    setState(() => _comments = raw is List
        ? raw.whereType<Map>().map((c) {
            final author = c['author'] is Map ? c['author'] as Map : {};
            final name = (author['name'] ?? c['author_name'] ?? '').toString();
            return <String, String>{
              'initials': Employee.initialsFor(name),
              'name': name,
              'time': (c['created_at'] ?? '').toString(),
              'text': (c['body'] ?? c['comment'] ?? '').toString()
            };
          }).toList()
        : []);
  }

  String _formatCommentTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24 && dt.day == now.day) {
        final hour =
            dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final minute = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $ampm';
      }
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, $hour:$minute $ampm';
    } catch (_) {
      return timeStr;
    }
  }

  @override
  void dispose() {
    WorkItemStore.instance.removeListener(_refresh);
    _commentController.dispose();
    super.dispose();
  }

  void _openActionSheet(String title) {
    if (!DemoSession.instance.isAdmin &&
        !StaffAccessStore.instance.allows(StaffPermission.editTask)) {
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskOptionsSheet(
        taskId: widget.taskId,
        taskTitle: title,
      ),
    );
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      await WorkItemStore.instance.addComment(widget.taskId, text);
      if (!mounted) return;
      _commentController.clear();
      NecToast.show(context,
          message: 'Comment added', type: NecToastType.success);
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: WorkItemStore.messageFor(error), type: NecToastType.error);
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'completed':
        return AppColors.success;
      case 'to_do':
      default:
        return AppColors.brandLight;
    }
  }

  Color _statusBgColor(String? status, NecColors nec) {
    return _statusColor(status).withValues(alpha: 0.12);
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'in_progress':
        return CupertinoIcons.flame_fill;
      case 'completed':
        return CupertinoIcons.checkmark_seal_fill;
      case 'to_do':
      default:
        return CupertinoIcons.circle;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await WorkItemStore.instance.update(widget.taskId, {'status': newStatus});
      if (!mounted) return;
      final label = newStatus == 'in_progress'
          ? 'In Progress'
          : (newStatus == 'completed' ? 'Completed' : 'To Do');
      NecToast.show(
        context,
        message: 'Task moved to $label',
        type: NecToastType.success,
      );
    } catch (error) {
      if (mounted) {
        NecToast.show(
          context,
          message: WorkItemStore.messageFor(error),
          type: NecToastType.error,
        );
      }
    }
  }

  Future<void> _completeTaskWithCelebration(String title) async {
    final confirmed = await TaskCompletionDialog.show(
      context,
      taskTitle: title,
      onConfirm: () async {
        await WorkItemStore.instance
            .update(widget.taskId, {'status': 'completed'});
      },
    );
    if (confirmed == true && mounted) {
      NecToast.show(
        context,
        message: 'Task completed successfully! 🎉',
        type: NecToastType.success,
      );
    }
  }

  void _showStatusSheet(BuildContext context, WorkItem? item) {
    final currentStatus = item?.status ?? 'to_do';
    final nec = Theme.of(context).extension<NecColors>()!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              const SizedBox(height: 14),
              Text(
                'Change Task Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: nec.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.2)),
              ListTile(
                leading: const Icon(CupertinoIcons.circle,
                    color: AppColors.brandLight),
                title: Text(
                  'To Do',
                  style: TextStyle(
                    fontWeight: currentStatus == 'to_do'
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: nec.textPrimary,
                  ),
                ),
                trailing: currentStatus == 'to_do'
                    ? const Icon(CupertinoIcons.checkmark_alt,
                        color: AppColors.brandLight)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (currentStatus != 'to_do') _updateStatus('to_do');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.flame_fill,
                    color: Color(0xFFF59E0B)),
                title: Text(
                  'In Progress',
                  style: TextStyle(
                    fontWeight: currentStatus == 'in_progress'
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: nec.textPrimary,
                  ),
                ),
                trailing: currentStatus == 'in_progress'
                    ? const Icon(CupertinoIcons.checkmark_alt,
                        color: Color(0xFFF59E0B))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (currentStatus != 'in_progress') {
                    _updateStatus('in_progress');
                  }
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.checkmark_seal_fill,
                    color: AppColors.success),
                title: Text(
                  'Completed (Done)',
                  style: TextStyle(
                    fontWeight: currentStatus == 'completed'
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: nec.textPrimary,
                  ),
                ),
                trailing: currentStatus == 'completed'
                    ? const Icon(CupertinoIcons.checkmark_alt,
                        color: AppColors.success)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (currentStatus != 'completed') {
                    _completeTaskWithCelebration(item?.title ?? 'Task');
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final item = WorkItemStore.instance.byId(widget.taskId);
    final taskTitle = item?.title ?? 'Task';
    final statusText = item?.status.replaceAll('_', ' ') ?? '';
    final relatedName = item?.leadName ?? 'No linked lead';
    final assignedName = item?.assigneeName ?? 'Unassigned';
    final assignedInitials = Employee.initialsFor(assignedName);
    final dueText =
        '${WorkQueueMapper.date(item?.scheduledAt)} ${WorkQueueMapper.time(item?.scheduledAt)}';
    final priorityText = item?.priority ?? '';
    final descriptionText = item?.description ?? '';
    final rawActivity =
        WorkItemStore.instance.detailsFor(widget.taskId)?['activity'];
    final activities = <Map<String, dynamic>>[
      if (rawActivity is List)
        for (final a in rawActivity.whereType<Map>())
          {
            'title': a['description']?.toString() ?? '',
            'subtitle': a['occurred_at']?.toString() ?? '',
            'icon': CupertinoIcons.checkmark_alt_circle_fill,
            'color': AppColors.brandLight
          },
    ];

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: nec.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: nec.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  'Task',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: DemoSession.instance.isAdmin ||
                        StaffAccessStore.instance
                            .allows(StaffPermission.editTask)
                    ? () => _openActionSheet(taskTitle)
                    : null,
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: nec.brand,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: nec.separator.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _showStatusSheet(context, item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusBgColor(item?.status, nec),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _statusColor(item?.status)
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon(item?.status),
                              size: 13,
                              color: _statusColor(item?.status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: _statusColor(item?.status),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.chevron_down,
                              size: 11,
                              color: _statusColor(item?.status),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      taskTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.brandLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.person_2,
                            color: AppColors.brandLight,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          'Related to',
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                        subtitle: Text(
                          relatedName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        trailing: Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: nec.textTertiary,
                        ),
                        onTap: item?.leadId == null
                            ? null
                            : () => context.push('/leads/${item!.leadId}'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            title: Text(
                              'Assigned To',
                              style: TextStyle(
                                fontSize: 13,
                                color: nec.textTertiary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NecAvatar(
                                  initials: assignedInitials,
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  assignedName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: nec.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.2),
                            indent: 16,
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            title: Text(
                              'Due',
                              style: TextStyle(
                                fontSize: 13,
                                color: nec.textTertiary,
                              ),
                            ),
                            trailing: Text(
                              dueText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: nec.textPrimary,
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.2),
                            indent: 16,
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            title: Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 13,
                                color: nec.textTertiary,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                priorityText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSectionHeader(context, 'DESCRIPTION'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        descriptionText,
                        style: TextStyle(
                          fontSize: 14,
                          color: nec.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    _buildSectionHeader(
                        context, 'COMMENTS (${_comments.length})'),
                    Material(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: List.generate(_comments.length, (index) {
                          final c = _comments[index];
                          final isLast = index == _comments.length - 1;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    NecAvatar(
                                      initials: c['initials']!,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  c['name']!,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: nec.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatCommentTime(c['time']!),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: nec.textTertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            c['text']!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: nec.textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  color: nec.separator.withValues(alpha: 0.2),
                                  indent: 60,
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        NecAvatar(
                          initials: Employee.initialsFor(
                              DemoSession.instance.user?.name ?? ''),
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: nec.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: nec.separator.withValues(alpha: 0.3),
                              ),
                            ),
                            child: TextField(
                              controller: _commentController,
                              onSubmitted: (_) => _addComment(),
                              style: TextStyle(
                                  color: nec.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: TextStyle(
                                  color: nec.textTertiary,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    CupertinoIcons.arrow_up_circle_fill,
                                    color: nec.brand,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: _addComment,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildSectionHeader(context, 'ATTACHMENTS'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.paperclip,
                            size: 16,
                            color: nec.textTertiary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'No attachments',
                            style: TextStyle(
                              fontSize: 14,
                              color: nec.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSectionHeader(context, 'ACTIVITY'),
                    Material(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: List.generate(activities.length, (index) {
                          final act = activities[index];
                          final isLast = index == activities.length - 1;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: (act['color'] as Color)
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        act['icon'] as IconData,
                                        size: 14,
                                        color: act['color'] as Color,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            act['title'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: nec.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            act['subtitle'] as String,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: nec.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Builder(
                builder: (context) {
                  final status = item?.status ?? 'to_do';
                  if (status == 'completed') {
                    return NecButton(
                      label: 'Reopen Task (To Do)',
                      icon: const Icon(CupertinoIcons.arrow_counterclockwise,
                          size: 15),
                      variant: NecButtonVariant.secondary,
                      onPressed: () => _updateStatus('to_do'),
                      fullWidth: true,
                    );
                  }
                  if (status == 'in_progress') {
                    return Row(
                      children: [
                        Expanded(
                          child: NecButton(
                            label: 'To Do',
                            icon: const Icon(CupertinoIcons.arrow_uturn_left,
                                size: 13),
                            variant: NecButtonVariant.secondary,
                            onPressed: () => _updateStatus('to_do'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NecButton(
                            label: 'Mark Done',
                            icon: const Icon(CupertinoIcons.checkmark_alt,
                                size: 16),
                            onPressed: () =>
                                _completeTaskWithCelebration(taskTitle),
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: NecButton(
                          label: 'In Progress',
                          icon: const Icon(CupertinoIcons.play_arrow_solid,
                              size: 13),
                          variant: NecButtonVariant.secondary,
                          onPressed: () => _updateStatus('in_progress'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NecButton(
                          label: 'Mark Done',
                          icon: const Icon(CupertinoIcons.checkmark_alt,
                              size: 16),
                          onPressed: () =>
                              _completeTaskWithCelebration(taskTitle),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
