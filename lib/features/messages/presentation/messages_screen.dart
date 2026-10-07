import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../team/data/employee_store.dart';
import '../data/message_store.dart';
import '../domain/models/chat_message.dart';
import 'widgets/message_recipient_picker.dart';
import 'widgets/messages_ui.dart';

enum _MessageFilter { all, unread, archived }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _query = '';
  _MessageFilter _filter = _MessageFilter.all;
  final _busyContacts = <String>{};
  bool _loading = true;
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    MessageStore.instance.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _compose() async {
    final employeeId = await chooseMessageRecipient(context);
    if (mounted && employeeId != null) {
      context.push('/messages/$employeeId');
    }
  }

  Future<void> _markAllRead() async {
    if (_markingRead) return;
    setState(() => _markingRead = true);
    try {
      await MessageStore.instance
          .markRead(archivedOnly: _filter == _MessageFilter.archived);
    } catch (_) {
      if (mounted) {
        NecToast.show(context,
            message: 'Unable to mark messages as read. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  Future<void> _conversationActions(MessageThread thread) async {
    final employee = EmployeeStore.instance.byId(thread.employeeId);
    if (employee == null || _busyContacts.contains(thread.employeeId)) return;
    final actor = DemoSession.instance.employeeId;
    final archived = MessageStore.instance.isArchived(thread.employeeId);
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(employee.name),
        actions: [
          CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 'archive'),
              child: Text(archived ? 'Move to Inbox' : 'Archive Conversation')),
          CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, 'delete'),
              child: const Text('Delete Conversation')),
        ],
        cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
      ),
    );
    if (!mounted ||
        action == null ||
        DemoSession.instance.employeeId != actor) {
      return;
    }
    await _changeConversation(thread.employeeId,
        delete: action == 'delete', archived: !archived);
  }

  Future<void> _changeConversation(String employeeId,
      {required bool delete, bool? archived}) async {
    if (_busyContacts.contains(employeeId)) return;
    final actor = DemoSession.instance.employeeId;
    final name =
        EmployeeStore.instance.byId(employeeId)?.name ?? 'this employee';
    _busyContacts.add(employeeId);
    try {
      if (delete) {
        final confirmed = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: const Text('Delete Conversation?'),
                  content: Text(
                      'Remove your messages with $name from your view? Their conversation history will remain available to them.'),
                  actions: [
                    CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete')),
                  ],
                ));
        if (confirmed != true) return;
      }
      if (!mounted ||
          !DemoSession.instance.signedIn ||
          DemoSession.instance.employeeId != actor) {
        return;
      }
      if (delete) {
        await MessageStore.instance.deleteConversation(employeeId);
      } else {
        await MessageStore.instance
            .archiveConversation(employeeId, archived: archived ?? true);
      }
      if (mounted && DemoSession.instance.employeeId == actor) {
        NecToast.show(context,
            message: delete
                ? 'Conversation deleted'
                : archived == false
                    ? 'Moved to Inbox'
                    : 'Conversation archived');
      }
    } catch (_) {
      if (mounted) {
        NecToast.show(context,
            message: 'Unable to update this conversation. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      _busyContacts.remove(employeeId);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([
          MessageStore.instance,
          EmployeeStore.instance,
          DemoSession.instance
        ]),
        builder: (context, _) {
          final nec = Theme.of(context).extension<NecColors>()!;
          final store = MessageStore.instance;
          final archived = _filter == _MessageFilter.archived;
          final unreadOnly = _filter == _MessageFilter.unread;
          final unreadCount =
              archived ? store.archivedUnreadCount : store.unreadCount;
          final query = _query.toLowerCase().trim();
          final threads = (archived ? store.archivedThreads : store.threads)
              .where((thread) {
            final employee = EmployeeStore.instance.byId(thread.employeeId)!;
            return (!unreadOnly || thread.unreadCount > 0) &&
                '${employee.name} ${employee.designation} ${thread.lastMessage.preview}'
                    .toLowerCase()
                    .contains(query);
          }).toList();
          return Scaffold(
            backgroundColor: nec.bg,
            appBar: messagesAppBar(context, 'Messages', actions: [
              if (unreadCount > 0 && store.loadError == null)
                CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    onPressed: _markingRead ? null : _markAllRead,
                    child: Tooltip(
                        message: 'Mark all as read',
                        child: Icon(CupertinoIcons.checkmark_circle,
                            color: nec.brand, size: 22))),
              CupertinoButton(
                  padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                  onPressed: _compose,
                  child: Tooltip(
                      message: 'New message',
                      child: Icon(CupertinoIcons.square_pencil,
                          color: nec.brand, size: 23))),
            ]),
            body: SafeArea(
                top: false,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: CupertinoSearchTextField(
                        placeholder: 'Search messages or people',
                        backgroundColor: nec.surface,
                        style: TextStyle(color: nec.textPrimary),
                        placeholderStyle: TextStyle(color: nec.textTertiary),
                        onChanged: (value) => setState(() => _query = value),
                      )),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<_MessageFilter>(
                          groupValue: _filter,
                          backgroundColor: nec.surface,
                          thumbColor: nec.brand,
                          padding: const EdgeInsets.all(4),
                          children: {
                            _MessageFilter.all: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                child: Text('All',
                                    style: TextStyle(
                                        color: _filter == _MessageFilter.all
                                            ? Colors.white
                                            : nec.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                            _MessageFilter.unread: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                child: Text(
                                    'Unread${store.unreadCount > 0 ? ' (${store.unreadCount})' : ''}',
                                    style: TextStyle(
                                        color: unreadOnly
                                            ? Colors.white
                                            : nec.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                            _MessageFilter.archived: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                child: Text(
                                    'Archived${store.archivedThreads.isNotEmpty ? ' (${store.archivedThreads.length})' : ''}',
                                    style: TextStyle(
                                        color: archived
                                            ? Colors.white
                                            : nec.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                          },
                          onValueChanged: (value) {
                            if (value != null) setState(() => _filter = value);
                          },
                        ),
                      )),
                  if (store.loadError != null)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text(store.loadError!,
                            style: const TextStyle(
                                color: CupertinoColors.systemRed))),
                  Expanded(
                      child: _loading
                          ? const Center(child: CupertinoActivityIndicator())
                          : threads.isEmpty
                              ? MessageEmptyState(
                                  title: query.isNotEmpty
                                      ? 'No matches found'
                                      : archived
                                          ? 'No archived conversations'
                                          : unreadOnly
                                              ? 'You’re all caught up'
                                              : 'Your team, one message away',
                                  subtitle: query.isNotEmpty
                                      ? 'Try another name or message.'
                                      : archived
                                          ? 'Archive a conversation by swiping right or holding it.'
                                          : unreadOnly
                                              ? 'New messages will appear here.'
                                              : 'Start a conversation with any staff member or admin.',
                                  actionLabel: query.isEmpty &&
                                          _filter == _MessageFilter.all
                                      ? 'New Message'
                                      : null,
                                  onAction: query.isEmpty &&
                                          _filter == _MessageFilter.all
                                      ? _compose
                                      : null,
                                )
                              : ListView(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            left: 4, bottom: 10),
                                        child: Text(
                                            archived
                                                ? 'ARCHIVED CONVERSATIONS'
                                                : 'CONVERSATIONS',
                                            style: TextStyle(
                                                color: nec.textTertiary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: .8))),
                                    Material(
                                        color: nec.surface,
                                        borderRadius: BorderRadius.circular(18),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(children: [
                                          for (var index = 0;
                                              index < threads.length;
                                              index++) ...[
                                            if (index > 0)
                                              Divider(
                                                  height: 1,
                                                  indent: 82,
                                                  color: nec.separator),
                                            _swipeableThread(
                                                threads[index], nec),
                                          ],
                                        ])),
                                  ],
                                )),
                ])),
          );
        },
      );

  Widget _swipeableThread(MessageThread thread, NecColors nec) {
    final archived = MessageStore.instance.isArchived(thread.employeeId);
    Widget background({required bool delete}) => Container(
        color: delete ? CupertinoColors.systemRed : nec.brand,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: delete
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
              delete
                  ? CupertinoIcons.trash
                  : archived
                      ? CupertinoIcons.tray_arrow_up
                      : CupertinoIcons.archivebox,
              color: Colors.white,
              size: 24),
          const SizedBox(height: 6),
          Text(
              delete
                  ? 'Delete'
                  : archived
                      ? 'Unarchive'
                      : 'Archive',
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]));
    return Dismissible(
        key: ValueKey(
            '${DemoSession.instance.employeeId}_${thread.employeeId}_${_filter.name}'),
        background: background(delete: false),
        secondaryBackground: background(delete: true),
        confirmDismiss: (direction) async {
          await _changeConversation(thread.employeeId,
              delete: direction == DismissDirection.endToStart,
              archived: !archived);
          // The store removes the row only after persistence succeeds.
          return false;
        },
        child: Material(color: nec.surface, child: _threadTile(thread, nec)));
  }

  Widget _threadTile(MessageThread thread, NecColors nec) {
    final employee = EmployeeStore.instance.byId(thread.employeeId)!;
    final last = thread.lastMessage;
    final mine = last.senderId == DemoSession.instance.employeeId;
    final unread = thread.unreadCount > 0;
    return InkWell(
      onTap: () => context.push('/messages/${employee.id}'),
      onLongPress: () => _conversationActions(thread),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            NecAvatar(
                initials: employee.avatarInitials,
                photoBase64: employee.photoBase64,
                size: 50),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(employee.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: nec.textPrimary,
                          fontSize: 15,
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(employee.designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: nec.textTertiary, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text('${mine ? 'You: ' : ''}${last.preview}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: unread ? nec.textPrimary : nec.textSecondary,
                          fontSize: 13,
                          height: 1.35)),
                ])),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(messageListTime(last.sentAt),
                  style: TextStyle(
                      color: unread ? nec.brand : nec.textTertiary,
                      fontSize: 10)),
              const SizedBox(height: 14),
              if (unread)
                Container(
                    constraints: const BoxConstraints(minWidth: 21),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                        color: nec.brand,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                        thread.unreadCount > 99
                            ? '99+'
                            : '${thread.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)))
              else
                Icon(CupertinoIcons.chevron_right,
                    color: nec.textTertiary, size: 12),
            ]),
          ])),
    );
  }
}
