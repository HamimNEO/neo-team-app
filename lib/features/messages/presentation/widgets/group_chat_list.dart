import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../team/domain/models/employee.dart';
import '../../data/group_chat_store.dart';
import '../../domain/models/group_chat.dart';
import 'group_chat_editor_sheet.dart';
import 'messages_ui.dart';

class GroupChatList extends StatelessWidget {
  const GroupChatList(
      {super.key,
      required this.kind,
      required this.query,
      required this.archived,
      required this.unreadOnly});

  final GroupChatKind kind;
  final String query;
  final bool archived, unreadOnly;

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!,
        store = GroupChatStore.instance;
    final groups = store.list(kind,
        query: query, archived: archived, unreadOnly: unreadOnly);
    final scopes = store.scopes.where((s) => s.kind == kind).toList();
    final manageable = scopes.any((s) => store.canManage(s));
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
          child: Row(children: [
            Expanded(
                child: Text(
                    '${kind == GroupChatKind.team ? 'TEAM' : 'DEPARTMENT'} CHANNELS',
                    style: TextStyle(
                        color: nec.textTertiary,
                        fontSize: 10,
                        letterSpacing: .5))),
            if (manageable)
              CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () async {
                    final group =
                        await showGroupChatEditor(context, kind: kind);
                    if (context.mounted && group != null) {
                      context.push('/message-groups/${group.id}');
                    }
                  },
                  child: Text('+ New Group',
                      style: TextStyle(color: nec.brand, fontSize: 13))),
          ])),
      if (store.error != null)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                  child: Text(store.error!,
                      style:
                          const TextStyle(color: CupertinoColors.systemRed))),
              CupertinoButton(onPressed: store.load, child: const Text('Retry'))
            ])),
      Expanded(
          child: groups.isEmpty
              ? MessageEmptyState(
                  title: query.isNotEmpty
                      ? 'No matches found'
                      : archived
                          ? 'No archived groups'
                          : unreadOnly
                              ? 'You’re all caught up'
                              : scopes.isEmpty
                                  ? 'No ${kind.name} assigned'
                                  : 'No group chats yet',
                  subtitle: query.isNotEmpty
                      ? 'Try another group name or message.'
                      : scopes.isEmpty
                          ? 'Your ${kind.name} chats will appear when you are assigned to one.'
                          : 'Your ${kind.name} lead or an admin can create a group for everyone.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final group = groups[index],
                        scope = store.scopeFor(groups[index])!;
                    final last = group.messages.lastOrNull,
                        unread = store.unreadFor(group);
                    return Material(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                            onTap: () =>
                                context.push('/message-groups/${group.id}'),
                            child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  NecAvatar(
                                      initials:
                                          Employee.initialsFor(group.name),
                                      photoBase64: group.photoBase64,
                                      photoUrl: group.photoUrl,
                                      size: 48),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(group.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: nec.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 3),
                                        Text('${scope.label} · ${scope.name}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: nec.textTertiary,
                                                fontSize: 11)),
                                        const SizedBox(height: 5),
                                        Text(
                                            last == null
                                                ? 'Start the conversation'
                                                : '${store.senderName(last.senderId)}: ${last.preview}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: nec.textSecondary,
                                                fontSize: 13)),
                                      ])),
                                  const SizedBox(width: 8),
                                  Column(children: [
                                    Text(
                                        messageListTime(
                                            last?.sentAt ?? group.createdAt),
                                        style: TextStyle(
                                            color: nec.textTertiary,
                                            fontSize: 10)),
                                    if (unread > 0)
                                      Container(
                                          margin:
                                              const EdgeInsets.only(top: 10),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                              color: nec.brand,
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Text(
                                              unread > 99 ? '99+' : '$unread',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11))),
                                  ]),
                                ]))));
                  })),
    ]);
  }
}
