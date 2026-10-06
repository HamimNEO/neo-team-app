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

  final List<Map<String, String>> _comments = [
    {
      'initials': 'KH',
      'name': 'Karim Hossain',
      'time': '10:30 AM',
      'text':
          'Please include the pricing sheet in the demo. Management will want to see the ROI breakdown.',
    },
    {
      'initials': 'MS',
      'name': 'Most. Shahina Akter',
      'time': '10:45 AM',
      'text':
          "Will do. I'll also add the competitor comparison slide as requested in last week's meeting.",
    },
  ];

  @override
  void dispose() {
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

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.add({
        'initials': 'MS',
        'name': 'Most. Shahina Akter',
        'time': 'Just now',
        'text': text,
      });
      _commentController.clear();
    });

    NecToast.show(
      context,
      message: 'Comment added',
      type: NecToastType.success,
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

    const taskTitle = 'Prepare Blue Wave Resort demo';
    const statusText = 'To Do';
    const relatedName = 'Blue Wave Resort';
    const assignedName = 'Most. Shahina Akter';
    const assignedInitials = 'MS';
    const dueText = 'Today · 2:00 PM';
    const priorityText = 'High';
    const descriptionText =
        'Create product demo presentation for the upcoming meeting with Blue Wave Resort management team.';

    final activities = [
      {
        'title': 'Task created',
        'subtitle': 'Karim Hossain · Sep 25 · 2:00 PM',
        'icon': CupertinoIcons.checkmark_alt_circle_fill,
        'color': AppColors.success,
      },
      {
        'title': 'Assigned to Most. Shahina Akter',
        'subtitle': 'Karim Hossain · Sep 25 · 2:01 PM',
        'icon': CupertinoIcons.person_fill,
        'color': AppColors.brandLight,
      },
      {
        'title': 'Priority changed to High',
        'subtitle': 'Karim Hossain · Sep 26 · 9:30 AM',
        'icon': CupertinoIcons.flag_fill,
        'color': AppColors.warning,
      },
      {
        'title': 'Comment added',
        'subtitle': 'Karim Hossain · Today · 10:30 AM',
        'icon': CupertinoIcons.chat_bubble_fill,
        'color': nec.textTertiary,
      },
      {
        'title': 'Comment added',
        'subtitle': 'Most. Shahina Akter · Today · 10:45 AM',
        'icon': CupertinoIcons.chat_bubble_fill,
        'color': nec.textTertiary,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: nec.textSecondary,
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
                        onTap: () => context.push('/leads/lead_1'),
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
                                const NecAvatar(
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
                              child: const Text(
                                priorityText,
                                style: TextStyle(
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
                                              Text(
                                                c['name']!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: nec.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                c['time']!,
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
                        const NecAvatar(
                          initials: 'MS',
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
              child: NecButton(
                label: 'Complete Task',
                onPressed: () {
                  context.pop();
                  NecToast.show(
                    context,
                    message: 'Task completed successfully',
                    type: NecToastType.success,
                  );
                },
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
