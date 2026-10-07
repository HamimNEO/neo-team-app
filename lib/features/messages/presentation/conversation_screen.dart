import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../team/data/employee_store.dart';
import '../data/message_store.dart';
import '../data/chat_attachment_picker.dart';
import '../domain/models/chat_attachment.dart';
import '../domain/models/chat_message.dart';
import 'widgets/chat_composer.dart';
import 'widgets/message_actions_sheet.dart';
import 'widgets/message_bubble.dart';
import 'widgets/messages_ui.dart';
import 'widgets/pinned_messages_bar.dart';

class ConversationScreen extends StatefulWidget {
  final String employeeId;

  const ConversationScreen({super.key, required this.employeeId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with WidgetsBindingObserver {
  final _composer = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _attachments = <PendingChatAttachment>[];
  late final String _ownerId;
  String? _replyToId;
  bool _loading = true;
  bool _sending = false;
  bool _reading = false;
  bool _picking = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _ownerId = DemoSession.instance.employeeId;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _composer.addListener(_refresh);
    MessageStore.instance.addListener(_messagesChanged);
    EmployeeStore.instance.addListener(_refresh);
    WidgetsBinding.instance.addObserver(this);
    MessageStore.instance.load().then((_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _markRead();
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _messagesChanged() {
    final reply = _replyToId == null
        ? null
        : MessageStore.instance.messageById(_replyToId!);
    if (_replyToId != null && (reply == null || reply.isDeleted)) {
      _replyToId = null;
    }
    _refresh();
    _markRead();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _markRead();
  }

  Future<void> _markRead() async {
    if (!mounted ||
        _loading ||
        _reading ||
        !_foreground ||
        ModalRoute.of(context)?.isCurrent != true ||
        _ownerId != DemoSession.instance.employeeId ||
        MessageStore.instance.loadError != null ||
        MessageStore.instance.unreadFor(widget.employeeId) == 0) {
      return;
    }
    _reading = true;
    try {
      await MessageStore.instance.markRead(employeeId: widget.employeeId);
    } catch (_) {
      if (mounted) _error('Unable to update read status.');
    } finally {
      _reading = false;
    }
  }

  void _error(String message) =>
      NecToast.show(context, message: message, type: NecToastType.error);

  Future<bool> _perform(Future<void> Function() action) async {
    if (_ownerId != DemoSession.instance.employeeId) return false;
    try {
      await action();
      return true;
    } catch (error) {
      if (mounted) {
        _error(error is FormatException
            ? error.message
            : 'Unable to save this change. Please try again.');
      }
      return false;
    }
  }

  Future<void> _pickAttachment() async {
    if (_picking || _sending) return;
    _focus.unfocus();
    setState(() => _picking = true);
    try {
      final source = await ChatAttachmentPicker.choose(context);
      if (!mounted || source == null) return;
      final selected = await ChatAttachmentPicker.pick(source);
      if (!mounted || _ownerId != DemoSession.instance.employeeId) return;
      final combined = [..._attachments, ...selected];
      if (combined.length > MessageStore.maxAttachmentCount ||
          combined.fold<int>(
                  0, (size, attachment) => size + attachment.bytes.length) >
              MessageStore.maxTotalBytes) {
        throw FormatException(
            'Attach up to 5 files, up to ${MessageStore.maxTotalBytes ~/ (1024 * 1024)} MB in total.');
      }
      setState(() => _attachments.addAll(selected));
    } catch (error) {
      if (mounted) {
        _error(error is FormatException
            ? error.message
            : 'Unable to add this attachment. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _reply(ChatMessage message) {
    if (_sending || message.isDeleted) return;
    setState(() => _replyToId = message.id);
    _focus.requestFocus();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (_sending ||
        _picking ||
        (text.isEmpty && _attachments.isEmpty) ||
        _ownerId != DemoSession.instance.employeeId) {
      return;
    }
    setState(() => _sending = true);
    try {
      await MessageStore.instance.send(widget.employeeId, text,
          attachments: List.of(_attachments), replyToId: _replyToId);
      if (!mounted) return;
      _attachments.clear();
      _replyToId = null;
      _composer.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut);
        }
      });
    } catch (error) {
      if (mounted) {
        _error(error is FormatException
            ? error.message
            : 'Unable to send. Your draft is still here.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showActions(ChatMessage message) async {
    _focus.unfocus();
    final selection = await chooseMessageAction(context, message);
    if (!mounted ||
        selection == null ||
        _ownerId != DemoSession.instance.employeeId) {
      return;
    }
    final current = MessageStore.instance.messageById(message.id);
    if (current == null) return;
    switch (selection.action) {
      case MessageAction.react:
        await _perform(
            () => MessageStore.instance.react(current.id, selection.emoji!));
        break;
      case MessageAction.reply:
        _reply(current);
        break;
      case MessageAction.pin:
        await _perform(() => MessageStore.instance.togglePin(current.id));
        break;
      case MessageAction.copy:
        if (!current.isDeleted && current.text.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: current.text));
          if (mounted) {
            NecToast.show(context,
                message: 'Message copied', type: NecToastType.info);
          }
        }
        break;
      case MessageAction.delete:
        await _delete(current);
        break;
    }
  }

  Future<void> _delete(ChatMessage message) async {
    final mine = message.senderId == _ownerId;
    final choice = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => CupertinoActionSheet(
            title: const Text('Delete Message'),
            message: Text(mine && !message.isDeleted
                ? 'Delete it from your view, or remove it for both people.'
                : 'This removes the message from your view only.'),
            actions: [
              if (mine && !message.isDeleted)
                CupertinoActionSheetAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete for Everyone')),
              CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Delete for Me')),
            ],
            cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'))));
    if (!mounted || choice == null) return;
    await _perform(() =>
        MessageStore.instance.deleteMessage(message.id, forEveryone: choice));
  }

  Future<void> _showPinned() async {
    final id = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => AnimatedBuilder(
            animation: MessageStore.instance,
            builder: (context, _) {
              final nec = Theme.of(context).extension<NecColors>()!;
              final pinned = MessageStore.instance.pinned(widget.employeeId);
              return Material(
                  color: nec.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                      top: false,
                      child: SizedBox(
                          height: MediaQuery.sizeOf(context).height * .55,
                          child: Column(children: [
                            const SizedBox(height: 16),
                            Text('Pinned Messages',
                                style: TextStyle(
                                    color: nec.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 14),
                            Divider(height: 1, color: nec.separator),
                            Expanded(
                                child: ListView.separated(
                                    itemCount: pinned.length,
                                    separatorBuilder: (_, __) => Divider(
                                        height: 1,
                                        indent: 16,
                                        color: nec.separator),
                                    itemBuilder: (context, index) {
                                      final message = pinned[index];
                                      return ListTile(
                                          leading: Icon(CupertinoIcons.pin_fill,
                                              color: nec.brand, size: 19),
                                          title: Text(message.preview,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: nec.textPrimary,
                                                  fontSize: 14)),
                                          subtitle: Text(
                                              '${EmployeeStore.instance.byId(message.senderId)?.name ?? 'Teammate'} · ${messageListTime(message.sentAt)}',
                                              style: TextStyle(
                                                  color: nec.textTertiary,
                                                  fontSize: 11)),
                                          onTap: () => Navigator.pop(
                                              sheetContext, message.id));
                                    })),
                          ]))));
            }));
    if (mounted && id != null) _showMessagePreview(id, pinned: true);
  }

  void _showMessagePreview(String id, {bool pinned = false}) {
    if (MessageStore.instance.messageById(id) == null) {
      _error('This message is no longer available.');
      return;
    }
    final nec = Theme.of(context).extension<NecColors>()!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
          backgroundColor: nec.bg,
          insetPadding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: AnimatedBuilder(
              animation: MessageStore.instance,
              builder: (context, _) {
                final message = MessageStore.instance.messageById(id);
                return ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .7),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
                          child: Row(children: [
                            Expanded(
                                child: Text(
                                    pinned
                                        ? 'Pinned Message'
                                        : 'Original Message',
                                    style: TextStyle(
                                        color: nec.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600))),
                            CupertinoButton(
                                padding: const EdgeInsets.all(8),
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Icon(CupertinoIcons.xmark_circle_fill,
                                    color: nec.textTertiary, size: 23)),
                          ])),
                      if (message == null)
                        Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('This message is no longer available.',
                                style: TextStyle(color: nec.textSecondary)))
                      else ...[
                        Flexible(
                            child:
                                SingleChildScrollView(child: _bubble(message))),
                        if (!message.isDeleted)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CupertinoButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          _reply(message);
                                        },
                                        child: const Text('Reply')),
                                    if (pinned && message.pinnedAt != null)
                                      CupertinoButton(
                                          onPressed: () {
                                            Navigator.pop(dialogContext);
                                            _perform(() => MessageStore.instance
                                                .togglePin(id));
                                          },
                                          child: const Text('Unpin')),
                                  ])),
                      ],
                    ]));
              })),
    );
  }

  Widget _bubble(ChatMessage message) => MessageBubble(
      message: message,
      mine: message.senderId == _ownerId,
      onActions: () => _showActions(message),
      onReply: () => _reply(message),
      onOpenReply: () {
        if (message.reply != null) {
          _showMessagePreview(message.reply!.messageId);
        }
      },
      onReact: (emoji) {
        _perform(() => MessageStore.instance.react(message.id, emoji));
      });

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MessageStore.instance.removeListener(_messagesChanged);
    EmployeeStore.instance.removeListener(_refresh);
    _composer.removeListener(_refresh);
    _composer.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final employee = EmployeeStore.instance.byId(widget.employeeId);
    if (employee == null || employee.id == _ownerId) {
      return Scaffold(
          backgroundColor: nec.bg,
          appBar: messagesAppBar(context, 'Conversation'),
          body: const MessageEmptyState(
              title: 'Choose a teammate',
              subtitle:
                  'Open Messages to start a conversation with another person.'));
    }
    final store = MessageStore.instance;
    final messages = store.conversation(employee.id);
    final pinned = store.pinned(employee.id);
    final reply = _replyToId == null ? null : store.messageById(_replyToId!);
    final enabled = !_loading &&
        store.loadError == null &&
        _ownerId == DemoSession.instance.employeeId;
    final canSend = enabled &&
        !_sending &&
        !_picking &&
        (_composer.text.trim().isNotEmpty || _attachments.isNotEmpty);
    return Scaffold(
      backgroundColor: nec.bg,
      resizeToAvoidBottomInset: true,
      appBar: messagesAppBar(
        context,
        employee.name,
        titleWidget: GestureDetector(
            onTap: () => context.push('/employee/${employee.id}'),
            child: Row(children: [
              NecAvatar(
                  initials: employee.avatarInitials,
                  photoBase64: employee.photoBase64,
                  size: 34),
              const SizedBox(width: 9),
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
                            fontWeight: FontWeight.w600)),
                    Text(employee.systemRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: nec.textTertiary, fontSize: 11)),
                  ])),
            ])),
        actions: [
          CupertinoButton(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              onPressed: () => context.push('/employee/${employee.id}'),
              child: Tooltip(
                  message: 'View profile',
                  child: Icon(CupertinoIcons.info_circle,
                      color: nec.brand, size: 23)))
        ],
      ),
      body: SafeArea(
          top: false,
          child: Column(children: [
            if (store.loadError != null)
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(store.loadError!,
                      style:
                          const TextStyle(color: CupertinoColors.systemRed))),
            if (pinned.isNotEmpty)
              PinnedMessagesBar(messages: pinned, onTap: _showPinned),
            Expanded(
                child: _loading
                    ? const Center(child: CupertinoActivityIndicator())
                    : messages.isEmpty
                        ? MessageEmptyState(
                            title: 'Say hello to ${employee.name}',
                            subtitle:
                                'Start a conversation, share an update, or send a photo.')
                        : ListView.builder(
                            controller: _scroll,
                            reverse: true,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            itemCount: messages.length,
                            itemBuilder: (context, reverseIndex) {
                              final index = messages.length - 1 - reverseIndex;
                              final message = messages[index];
                              final startsDay = index == 0 ||
                                  messageDay(messages[index - 1].sentAt) !=
                                      messageDay(message.sentAt);
                              return Column(
                                  key: ValueKey(message.id),
                                  children: [
                                    if (startsDay)
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                  color: nec.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: Text(
                                                  messageDay(message.sentAt),
                                                  style: TextStyle(
                                                      color: nec.textTertiary,
                                                      fontSize: 11)))),
                                    _bubble(message),
                                  ]);
                            })),
            ChatComposer(
              controller: _composer,
              focusNode: _focus,
              replyName: reply == null
                  ? null
                  : reply.senderId == _ownerId
                      ? 'yourself'
                      : EmployeeStore.instance.byId(reply.senderId)?.name ??
                          'teammate',
              replyPreview: reply?.preview,
              attachments: _attachments,
              enabled: enabled,
              canSend: canSend,
              sending: _sending,
              picking: _picking,
              onAttach: _pickAttachment,
              onSend: _send,
              onCancelReply: () => setState(() => _replyToId = null),
              onRemoveAttachment: (index) =>
                  setState(() => _attachments.removeAt(index)),
            ),
          ])),
    );
  }
}
