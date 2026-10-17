import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../team/domain/models/employee.dart';
import '../data/chat_attachment_picker.dart';
import '../data/group_chat_store.dart';
import '../data/message_store.dart';
import '../domain/models/chat_attachment.dart';
import '../domain/models/chat_message.dart';
import 'widgets/chat_composer.dart';
import 'widgets/message_actions_sheet.dart';
import 'widgets/message_bubble.dart';
import 'widgets/messages_ui.dart';

class GroupConversationScreen extends StatefulWidget {
  const GroupConversationScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupConversationScreen> createState() =>
      _GroupConversationScreenState();
}

class _GroupConversationScreenState extends State<GroupConversationScreen>
    with WidgetsBindingObserver {
  final _composer = TextEditingController(),
      _focus = FocusNode(),
      _scroll = ScrollController();
  final _attachments = <PendingChatAttachment>[];
  late final String _actor;
  late final String? _token;
  bool _loading = true, _sending = false, _picking = false, _reading = false;
  bool _foreground = true;
  String? _replyId;
  Timer? _pollTimer;

  bool get _sameSession =>
      _actor == DemoSession.instance.employeeId &&
      _token == DemoSession.instance.accessToken;

  @override
  void initState() {
    super.initState();
    _actor = DemoSession.instance.employeeId;
    _token = DemoSession.instance.accessToken;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _composer.addListener(_refresh);
    GroupChatStore.instance.addListener(_changed);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_foreground && mounted && ModalRoute.of(context)?.isCurrent == true) {
        GroupChatStore.instance.syncRemote().ignore();
      }
    });
    GroupChatStore.instance.load().then((_) {
      if (!mounted) return;
      GroupChatStore.instance.syncRemote().ignore();
      setState(() => _loading = false);
      _markRead();
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _changed() {
    _refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _markRead();
  }

  Future<void> _markRead() async {
    final group = GroupChatStore.instance.byId(widget.groupId);
    if (!mounted ||
        _loading ||
        _reading ||
        !_foreground ||
        !_sameSession ||
        ModalRoute.of(context)?.isCurrent != true ||
        group == null ||
        GroupChatStore.instance.unreadFor(group) == 0) {
      return;
    }
    _reading = true;
    try {
      await GroupChatStore.instance.markRead(group.id);
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      _reading = false;
    }
  }

  void _error(Object e) => NecToast.show(context,
      type: NecToastType.error,
      message: e is FormatException
          ? e.message
          : 'Unable to save this change. Try again.');

  Future<void> _perform(Future<void> Function() action) async {
    if (!_sameSession) return;
    try {
      await action();
    } catch (e) {
      if (mounted) _error(e);
    }
  }

  void _reply(ChatMessage message) {
    if (_sending || _picking || message.isDeleted) return;
    setState(() => _replyId = message.id);
    _focus.requestFocus();
  }

  Future<void> _pick() async {
    if (_sending || _picking) return;
    setState(() => _picking = true);
    try {
      final source = await ChatAttachmentPicker.choose(context);
      if (!mounted || source == null || !_sameSession) return;
      final selected = await ChatAttachmentPicker.pick(source);
      if (!mounted || !_sameSession) return;
      final combined = [..._attachments, ...selected];
      if (combined.length > MessageStore.maxAttachmentCount ||
          combined.fold<int>(0, (sum, a) => sum + a.bytes.length) >
              MessageStore.maxTotalBytes) {
        throw const FormatException(
            'Choose up to 5 attachments within the total file-size limit.');
      }
      setState(() => _attachments.addAll(selected));
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _send() async {
    if (_sending || _picking || !_sameSession) return;
    setState(() => _sending = true);
    try {
      await GroupChatStore.instance.send(widget.groupId, _composer.text,
          attachments: List.of(_attachments), replyToId: _replyId);
      if (!mounted || !_sameSession) return;
      _attachments.clear();
      _replyId = null;
      _composer.clear();
      if (_scroll.hasClients) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _actions(ChatMessage message) async {
    final selection = await chooseMessageAction(context, message);
    if (!mounted || !_sameSession || selection == null) return;
    switch (selection.action) {
      case MessageAction.react:
        await _perform(() => GroupChatStore.instance
            .react(widget.groupId, message.id, selection.emoji!));
        break;
      case MessageAction.reply:
        _reply(message);
        break;
      case MessageAction.pin:
        break;
      case MessageAction.copy:
        if (!message.isDeleted && message.text.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: message.text));
        }
        break;
      case MessageAction.delete:
        await _perform(() =>
            GroupChatStore.instance.deleteMessage(widget.groupId, message.id));
        break;
    }
  }

  Widget _bubble(ChatMessage message) => MessageBubble(
      message: message,
      mine: message.senderId == _actor,
      onActions: () => _actions(message),
      replySenderName: message.reply == null
          ? null
          : GroupChatStore.instance.senderName(message.reply!.senderId),
      onReply: () => _reply(message),
      onReact: (emoji) => _perform(() =>
          GroupChatStore.instance.react(widget.groupId, message.id, emoji)),
      onOpenReply: () {
        final original = GroupChatStore.instance
            .byId(widget.groupId)
            ?.messages
            .where((m) => m.id == message.reply?.messageId)
            .firstOrNull;
        if (original != null) {
          showDialog<void>(
              context: context,
              builder: (c) => Dialog(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _bubble(original))));
        }
      });

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    GroupChatStore.instance.removeListener(_changed);
    _composer.removeListener(_refresh);
    _composer.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!,
        store = GroupChatStore.instance;
    final group = _sameSession ? store.byId(widget.groupId) : null;
    final scope = group == null ? null : store.scopeFor(group);
    if (_loading) {
      return Scaffold(
          backgroundColor: nec.bg,
          appBar: messagesAppBar(context, 'Group Chat'),
          body: const Center(child: CupertinoActivityIndicator()));
    }
    if (group == null || scope == null) {
      return Scaffold(
          backgroundColor: nec.bg,
          appBar: messagesAppBar(context, 'Group Chat'),
          body: const MessageEmptyState(
              title: 'Group unavailable',
              subtitle: 'The group was deleted or your membership changed.'));
    }
    final reply = group.messages
        .where((m) => m.id == _replyId && !m.isDeleted)
        .firstOrNull;
    return Scaffold(
        backgroundColor: nec.bg,
        appBar: messagesAppBar(context, group.name,
            titleWidget: GestureDetector(
                onTap: () =>
                    context.push('/message-groups/${group.id}/details'),
                child: Row(children: [
                  NecAvatar(
                      initials: Employee.initialsFor(group.name),
                      photoBase64: group.photoBase64,
                      photoUrl: group.photoUrl,
                      size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: nec.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        Text('${scope.label} chat',
                            style: TextStyle(
                                color: nec.textTertiary, fontSize: 11)),
                      ]))
                ])),
            actions: [
              CupertinoButton(
                  padding: const EdgeInsets.all(12),
                  onPressed: () =>
                      context.push('/message-groups/${group.id}/details'),
                  child: Icon(CupertinoIcons.info_circle,
                      color: nec.brand, size: 22))
            ]),
        body: SafeArea(
            top: false,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('${scope.label} discussion · ${group.name}',
                      style: TextStyle(color: nec.textTertiary, fontSize: 11))),
              Expanded(
                  child: group.messages.isEmpty
                      ? const MessageEmptyState(
                          title: 'Start the conversation',
                          subtitle: 'Share an update with your group.')
                      : ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: group.messages.length,
                          itemBuilder: (_, index) {
                            final message = group
                                .messages[group.messages.length - 1 - index];
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 8, 20, 2),
                                      child: Text(messageDay(message.sentAt),
                                          style: TextStyle(
                                              color: nec.textTertiary,
                                              fontSize: 10))),
                                  if (message.senderId != _actor)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(left: 24),
                                        child: Text(
                                            store.senderName(message.senderId),
                                            style: TextStyle(
                                                color: nec.brand,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600))),
                                  _bubble(message),
                                ]);
                          })),
              ChatComposer(
                  controller: _composer,
                  focusNode: _focus,
                  attachments: _attachments,
                  replyName:
                      reply == null ? null : store.senderName(reply.senderId),
                  replyPreview: reply?.preview,
                  enabled: !_loading && _sameSession && store.error == null,
                  canSend: !_sending &&
                      !_picking &&
                      store.error == null &&
                      (_composer.text.trim().isNotEmpty ||
                          _attachments.isNotEmpty),
                  sending: _sending,
                  picking: _picking,
                  onAttach: _pick,
                  onSend: _send,
                  onCancelReply: () => setState(() => _replyId = null),
                  onRemoveAttachment: (i) =>
                      setState(() => _attachments.removeAt(i))),
            ])));
  }
}
