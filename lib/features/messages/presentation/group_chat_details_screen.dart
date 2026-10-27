import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../team/domain/models/employee.dart';
import '../../team/data/employee_store.dart';
import '../data/group_chat_store.dart';
import '../domain/models/group_chat.dart';
import 'widgets/group_chat_editor_sheet.dart';
import 'widgets/messages_ui.dart';

class GroupChatDetailsScreen extends StatelessWidget {
  const GroupChatDetailsScreen({super.key, required this.groupId});

  final String groupId;

  Future<void> _delete(BuildContext context, GroupChat group) async {
    final actor = DemoSession.instance.employeeId,
        token = DemoSession.instance.accessToken;
    final confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (c) => CupertinoAlertDialog(
                title: const Text('Delete Group?'),
                content: const Text(
                    'The group and its message history will be permanently deleted for all participants.'),
                actions: [
                  CupertinoDialogAction(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Delete'))
                ]));
    if (!context.mounted ||
        confirm != true ||
        actor != DemoSession.instance.employeeId ||
        token != DemoSession.instance.accessToken) {
      return;
    }
    try {
      await GroupChatStore.instance.delete(group.id);
      if (context.mounted) context.go('/messages');
    } catch (e) {
      if (context.mounted) _error(context, e);
    }
  }

  void _error(BuildContext context, Object e) => NecToast.show(context,
      message: e is FormatException
          ? e.message
          : 'Unable to update this group. Try again.',
      type: NecToastType.error);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: GroupChatStore.instance,
      builder: (context, _) {
        final nec = Theme.of(context).extension<NecColors>()!,
            store = GroupChatStore.instance;
        final group = store.byId(groupId),
            scope = group == null ? null : store.scopeFor(group);
        if (group == null || scope == null) {
          return Scaffold(
              backgroundColor: nec.bg,
              appBar: messagesAppBar(context, 'Group Info'),
              body: const MessageEmptyState(
                  title: 'Group unavailable',
                  subtitle:
                      'The group was deleted or your membership changed.'));
        }
        final manageable = store.canManage(scope),
            members = store.conversationMembers(group);
        return Scaffold(
            backgroundColor: nec.bg,
            appBar: messagesAppBar(context, 'Group Info', actions: [
              if (manageable)
                CupertinoButton(
                    onPressed: () => showGroupChatEditor(context,
                        kind: scope.kind, group: group),
                    child: const Text('Edit')),
            ]),
            body: SafeArea(
                top: false,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Center(
                      child: NecAvatar(
                          initials: Employee.initialsFor(group.name),
                          photoBase64: group.photoBase64,
                          photoUrl: group.photoUrl,
                          size: 82)),
                  const SizedBox(height: 14),
                  Text(group.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: nec.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('${scope.label} · ${scope.name}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: nec.textSecondary, fontSize: 13)),
                  const SizedBox(height: 20),
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Text(
                          group.description.isEmpty
                              ? 'No description yet'
                              : group.description,
                          style: TextStyle(
                              color: nec.textSecondary,
                              fontSize: 14,
                              height: 1.4))),
                  const SizedBox(height: 20),
                  Text('PARTICIPANTS',
                      style: TextStyle(color: nec.textTertiary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('Conversation participants returned by the server.',
                      style: TextStyle(
                          color: nec.textSecondary, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 10),
                  if (manageable)
                    TextButton.icon(
                        onPressed: () async {
                          final member = await showModalBottomSheet<Employee>(
                              context: context,
                              builder: (sheet) => SafeArea(
                                      child:
                                          ListView(shrinkWrap: true, children: [
                                    const ListTile(
                                        title: Text('Add participant')),
                                    for (final employee in EmployeeStore
                                        .instance.staffEmployees
                                        .where((e) =>
                                            e.status == 'Active' &&
                                            !members.any((m) => m.id == e.id)))
                                      ListTile(
                                          title: Text(employee.name),
                                          subtitle: Text(employee.designation),
                                          onTap: () =>
                                              Navigator.pop(sheet, employee)),
                                  ])));
                          if (member == null) return;
                          try {
                            await store.addMember(group.id, member);
                          } catch (e) {
                            if (context.mounted) _error(context, e);
                          }
                        },
                        icon: const Icon(CupertinoIcons.person_add),
                        label: const Text('Add participant')),
                  for (final member in members)
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: NecAvatar(
                            initials: member.avatarInitials,
                            photoBase64: member.photoBase64,
                            photoUrl: member.photoUrl,
                            size: 38),
                        title: Text(member.name,
                            style: TextStyle(
                                color: nec.textPrimary, fontSize: 14)),
                        subtitle: Text(
                            member.id == group.createdBy
                                ? '${member.designation} · Creator'
                                : member.designation,
                            style: TextStyle(
                                color: nec.textTertiary, fontSize: 12)),
                        trailing: manageable &&
                                member.id != group.createdBy &&
                                member.id != DemoSession.instance.employeeId
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.minus_circle,
                                    color: AppColors.error, size: 20),
                                tooltip: 'Remove participant',
                                onPressed: () async {
                                  final confirm =
                                      await showCupertinoDialog<bool>(
                                    context: context,
                                    builder: (c) => CupertinoAlertDialog(
                                      title: const Text('Remove Participant?'),
                                      content: Text(
                                          'Remove ${member.name} from ${group.name}?'),
                                      actions: [
                                        CupertinoDialogAction(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text('Cancel'),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await store.removeMember(
                                          group.id, member);
                                      if (context.mounted) {
                                        NecToast.show(context,
                                            message:
                                                '${member.name} was removed from the group.',
                                            type: NecToastType.success);
                                      }
                                    } catch (e) {
                                      if (context.mounted) _error(context, e);
                                    }
                                  }
                                },
                              )
                            : null),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(CupertinoIcons.shield, color: nec.brand),
                      title: Text('Admins',
                          style:
                              TextStyle(color: nec.textPrimary, fontSize: 14)),
                      subtitle: Text('Workspace administration',
                          style: TextStyle(
                              color: nec.textTertiary, fontSize: 12))),
                  const SizedBox(height: 16),
                  CupertinoButton(
                      onPressed: () async {
                        try {
                          await store.archive(
                              group.id, !store.isArchived(group));
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) _error(context, e);
                        }
                      },
                      child: Text(store.isArchived(group)
                          ? 'Move to Inbox'
                          : 'Archive Group')),
                  if (manageable)
                    CupertinoButton(
                        onPressed: () => _delete(context, group),
                        child: const Text('Delete Group',
                            style: TextStyle(color: CupertinoColors.systemRed)))
                  else
                    CupertinoButton(
                        onPressed: () async {
                          final confirmed = await showCupertinoDialog<bool>(
                              context: context,
                              builder: (ctx) => CupertinoAlertDialog(
                                    title: const Text('Leave Group?'),
                                    content: Text(
                                        'Are you sure you want to leave ${group.name}?'),
                                    actions: [
                                      CupertinoDialogAction(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel')),
                                      CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Leave')),
                                    ],
                                  ));
                          if (confirmed != true) return;
                          try {
                            await store.leaveGroup(group.id);
                            if (context.mounted) {
                              context.pop();
                              NecToast.show(context,
                                  message: 'You have left the group.');
                            }
                          } catch (e) {
                            if (context.mounted) _error(context, e);
                          }
                        },
                        child: const Text('Leave Group',
                            style:
                                TextStyle(color: CupertinoColors.systemRed))),
                ])));
      });
}
