import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/demo_session.dart';
import '../../team/data/employee_store.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chat_attachment.dart';
import 'attachment_storage.dart';

/// Local shared conversations for the UI phase. No messages are sent remotely.
class MessageStore extends ChangeNotifier {
  MessageStore._();

  static final instance = MessageStore._();
  static const _key = 'nec_messages_v1';
  List<ChatMessage> _messages = [];
  Map<String, List<String>> _archives = {};
  Future<void>? _loading;
  Future<void> _pending = Future<void>.value();
  int _sequence = 0;
  String? loadError;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) {
        final sample = _seed();
        if (!await prefs.setString(_key, _encode(sample, {}))) {
          throw const FormatException('Unable to initialize conversations.');
        }
        _messages = sample;
      } else {
        final decoded = jsonDecode(raw);
        final records =
            decoded is List ? decoded : (decoded as Map)['messages'] as List;
        final restored = records
            .map((item) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (restored.map((message) => message.id).toSet().length !=
            restored.length) {
          throw const FormatException('Duplicate message record.');
        }
        _messages = restored;
        if (decoded is Map && decoded['archives'] is Map) {
          _archives = (decoded['archives'] as Map).map((owner, contacts) =>
              MapEntry(owner as String, List<String>.from(contacts as List)));
        }
      }
    } catch (_) {
      loadError = 'Messages could not be loaded. Restart the app to try again.';
    }
  }

  List<ChatMessage> conversation(String employeeId) {
    if (!DemoSession.instance.signedIn) return const [];
    final me = DemoSession.instance.employeeId;
    final messages = _messages
        .where((message) =>
            message.isBetween(me, employeeId) &&
            !message.hiddenFor.contains(me))
        .toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return List.unmodifiable(messages);
  }

  List<MessageThread> get _allThreads {
    if (!DemoSession.instance.signedIn) return const [];
    final me = DemoSession.instance.employeeId;
    final latest = <String, ChatMessage>{};
    final unread = <String, int>{};
    for (final message in _messages.where(
        (message) => message.involves(me) && !message.hiddenFor.contains(me))) {
      final other =
          message.senderId == me ? message.recipientId : message.senderId;
      if (EmployeeStore.instance.byId(other) == null) continue;
      if (latest[other] == null ||
          !message.sentAt.isBefore(latest[other]!.sentAt)) {
        latest[other] = message;
      }
      if (message.recipientId == me &&
          !message.isDeleted &&
          message.readAt == null) {
        unread[other] = (unread[other] ?? 0) + 1;
      }
    }
    return latest.entries
        .map((entry) => MessageThread(
            employeeId: entry.key,
            lastMessage: entry.value,
            unreadCount: unread[entry.key] ?? 0))
        .toList()
      ..sort((a, b) => b.lastMessage.sentAt.compareTo(a.lastMessage.sentAt));
  }

  bool isArchived(String employeeId) =>
      DemoSession.instance.signedIn &&
      (_archives[DemoSession.instance.employeeId]?.contains(employeeId) ??
          false);

  List<MessageThread> get threads =>
      _allThreads.where((thread) => !isArchived(thread.employeeId)).toList();

  List<MessageThread> get archivedThreads =>
      _allThreads.where((thread) => isArchived(thread.employeeId)).toList();

  int get archivedUnreadCount =>
      archivedThreads.fold(0, (count, thread) => count + thread.unreadCount);

  int get unreadCount =>
      threads.fold(0, (count, thread) => count + thread.unreadCount);

  int unreadFor(String employeeId) => conversation(employeeId)
      .where((message) =>
          message.recipientId == DemoSession.instance.employeeId &&
          !message.isDeleted &&
          message.readAt == null)
      .length;

  void _authorize(String actorId) {
    if (!DemoSession.instance.signedIn ||
        DemoSession.instance.employeeId != actorId) {
      throw const FormatException('Sign in again to continue messaging.');
    }
    if (loadError != null) throw FormatException(loadError!);
  }

  String _encode(
          List<ChatMessage> messages, Map<String, List<String>> archives) =>
      jsonEncode({
        'version': 2,
        'messages': messages.map((message) => message.toJson()).toList(),
        'archives': archives,
      });

  Future<void> _write(String actorId,
      FutureOr<List<ChatMessage>> Function(List<ChatMessage>) update,
      {void Function(Map<String, List<String>>)? updateArchives}) async {
    await load();
    final operation = _pending.then((_) async {
      _authorize(actorId);
      final updated = await update(List.of(_messages));
      final archives = _archives
          .map((owner, contacts) => MapEntry(owner, List<String>.of(contacts)));
      updateArchives?.call(archives);
      final prefs = await SharedPreferences.getInstance();
      _authorize(actorId);
      if (!await prefs.setString(_key, _encode(updated, archives))) {
        throw const FormatException(
            'Unable to save the message. Please try again.');
      }
      _messages = updated;
      _archives = archives;
      notifyListeners();
    });
    _pending =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    await operation;
  }

  Future<void> archiveConversation(String employeeId,
      {required bool archived}) {
    final me = DemoSession.instance.employeeId;
    return _write(me, (messages) {
      if (employeeId == me || EmployeeStore.instance.byId(employeeId) == null) {
        throw const FormatException('This employee is no longer available.');
      }
      return messages;
    }, updateArchives: (archives) {
      final contacts = archives.putIfAbsent(me, () => []);
      contacts.remove(employeeId);
      if (archived) contacts.add(employeeId);
    });
  }

  Future<void> deleteConversation(String employeeId) {
    final me = DemoSession.instance.employeeId;
    return _write(
        me,
        (messages) => messages
            .map((message) => message.isBetween(me, employeeId) &&
                    !message.hiddenFor.contains(me)
                ? message.copyWith(hiddenFor: [...message.hiddenFor, me])
                : message)
            .toList(), updateArchives: (archives) {
      archives[me]?.remove(employeeId);
    });
  }

  static const maxAttachmentCount = 5;

  static int get maxAttachmentBytes => (kIsWeb ? 2 : 10) * 1024 * 1024;

  static int get maxTotalBytes => (kIsWeb ? 2 : 25) * 1024 * 1024;

  List<ChatMessage> pinned(String employeeId) => conversation(employeeId)
      .where((message) => message.pinnedAt != null && !message.isDeleted)
      .toList()
    ..sort((a, b) => b.pinnedAt!.compareTo(a.pinnedAt!));

  ChatMessage? messageById(String id) {
    if (!DemoSession.instance.signedIn) return null;
    final me = DemoSession.instance.employeeId;
    for (final message in _messages) {
      if (message.id == id &&
          message.involves(me) &&
          !message.hiddenFor.contains(me)) {
        return message;
      }
    }
    return null;
  }

  ChatMessage _target(List<ChatMessage> messages, String id, String actor,
      {bool allowDeleted = false}) {
    for (final message in messages) {
      if (message.id == id &&
          message.involves(actor) &&
          !message.hiddenFor.contains(actor)) {
        if (message.isDeleted && !allowDeleted) {
          throw const FormatException('This message was deleted.');
        }
        return message;
      }
    }
    throw const FormatException('This message is no longer available.');
  }

  Future<void> send(String employeeId, String text,
      {List<PendingChatAttachment> attachments = const [],
      String? replyToId}) async {
    final me = DemoSession.instance.employeeId;
    final value = text.trim();
    final saved = <ChatAttachment>[];
    try {
      await _write(me, (messages) async {
        if (employeeId == me ||
            EmployeeStore.instance.byId(employeeId) == null) {
          throw const FormatException('Choose another employee to message.');
        }
        if ((value.isEmpty && attachments.isEmpty) || value.length > 4000) {
          throw const FormatException(
              'Add text or an attachment. Text can be up to 4,000 characters.');
        }
        if (attachments.length > maxAttachmentCount ||
            attachments.any((attachment) =>
                attachment.bytes.isEmpty ||
                attachment.bytes.length > maxAttachmentBytes) ||
            attachments.fold<int>(
                    0, (size, attachment) => size + attachment.bytes.length) >
                maxTotalBytes) {
          throw FormatException(
              'Attach up to 5 files, up to ${maxAttachmentBytes ~/ (1024 * 1024)} MB each and ${maxTotalBytes ~/ (1024 * 1024)} MB in total.');
        }
        ChatReply? reply;
        if (replyToId != null) {
          final original = _target(messages, replyToId, me);
          if (!original.isBetween(me, employeeId)) {
            throw const FormatException(
                'Reply to a message in this conversation.');
          }
          reply = ChatReply(
              messageId: original.id,
              senderId: original.senderId,
              preview: original.preview.length > 300
                  ? original.preview.substring(0, 300)
                  : original.preview);
        }
        final now = DateTime.now();
        final id = '${me}_${now.microsecondsSinceEpoch}_${_sequence++}';
        for (var index = 0; index < attachments.length; index++) {
          saved.add(
              await AttachmentStorage.save(attachments[index], '${id}_$index'));
        }
        messages.add(ChatMessage(
            id: id,
            senderId: me,
            recipientId: employeeId,
            text: value,
            sentAt: now,
            attachments: List.unmodifiable(saved),
            reply: reply));
        return messages;
      });
    } catch (_) {
      for (final attachment in saved) {
        await AttachmentStorage.remove(attachment);
      }
      rethrow;
    }
  }

  Future<void> _updateMessage(
      String id, ChatMessage Function(ChatMessage) update) {
    final me = DemoSession.instance.employeeId;
    return _write(me, (messages) {
      final target = _target(messages, id, me);
      messages[messages.indexOf(target)] = update(target);
      return messages;
    });
  }

  Future<void> react(String id, String emoji) {
    final me = DemoSession.instance.employeeId;
    return _updateMessage(id, (message) {
      if (!ChatMessage.reactionOptions.contains(emoji)) {
        throw const FormatException('Choose a supported reaction.');
      }
      final reactions = Map<String, String>.of(message.reactions);
      if (reactions[me] == emoji) {
        reactions.remove(me);
      } else {
        reactions[me] = emoji;
      }
      return message.copyWith(reactions: Map.unmodifiable(reactions));
    });
  }

  Future<void> togglePin(String id) => _updateMessage(
      id,
      (message) => message.copyWith(
          pinnedAt: message.pinnedAt == null ? DateTime.now() : null,
          unpin: message.pinnedAt != null));

  Future<void> deleteMessage(String id, {required bool forEveryone}) async {
    final me = DemoSession.instance.employeeId;
    final cleanup = <ChatAttachment>[];
    await _write(me, (messages) {
      final target = _target(messages, id, me, allowDeleted: true);
      if (!forEveryone) {
        messages[messages.indexOf(target)] =
            target.copyWith(hiddenFor: [...target.hiddenFor, me]);
      } else {
        if (target.senderId != me) {
          throw const FormatException(
              'You can only delete your own messages for everyone.');
        }
        cleanup.addAll(target.attachments);
        messages[messages.indexOf(target)] = target.copyWith(
            text: '',
            attachments: [],
            reactions: {},
            isDeleted: true,
            clearReply: true,
            unpin: true);
        for (var index = 0; index < messages.length; index++) {
          final message = messages[index];
          if (message.reply?.messageId == id) {
            messages[index] = message.copyWith(
                reply: ChatReply(
                    messageId: id,
                    senderId: target.senderId,
                    preview: 'Message deleted'));
          }
        }
      }
      return messages;
    });
    for (final attachment in cleanup) {
      await AttachmentStorage.remove(attachment);
    }
  }

  Future<void> markRead({String? employeeId, bool? archivedOnly}) {
    final me = DemoSession.instance.employeeId;
    return _write(me, (messages) {
      final now = DateTime.now();
      return messages
          .map((message) => message.recipientId == me &&
                  !message.isDeleted &&
                  !message.hiddenFor.contains(me) &&
                  message.readAt == null &&
                  (archivedOnly == null ||
                      (_archives[me]?.contains(message.senderId) ?? false) ==
                          archivedOnly) &&
                  (employeeId == null || message.senderId == employeeId)
              ? message.markRead(now)
              : message)
          .toList();
    });
  }

  List<ChatMessage> _seed() {
    final now = DateTime.now();
    const admin = DemoSession.adminEmployeeId;
    const staff = DemoSession.staffEmployeeId;
    ChatMessage sample(
            String id, String from, String to, String text, Duration ago,
            {bool read = false}) =>
        ChatMessage(
            id: id,
            senderId: from,
            recipientId: to,
            text: text,
            sentAt: now.subtract(ago),
            readAt: read
                ? now.subtract(ago).add(const Duration(minutes: 1))
                : null);
    return [
      sample(
          'sample_1',
          admin,
          staff,
          'Hi Shahina, how is the client follow-up going?',
          const Duration(days: 1, hours: 2),
          read: true),
      sample(
          'sample_2',
          staff,
          admin,
          'Good morning! I have updated the leads and scheduled the visits.',
          const Duration(days: 1, hours: 1),
          read: true),
      sample(
          'sample_3',
          admin,
          staff,
          'Great work. Please share the update before our meeting today.',
          const Duration(minutes: 18)),
      sample(
          'sample_4',
          'emp_yeapas',
          admin,
          'The latest app screens are ready for your review.',
          const Duration(minutes: 42)),
      sample(
          'sample_5',
          'emp_sultana',
          admin,
          'I have shared the team schedule for this week.',
          const Duration(days: 1)),
      sample(
          'sample_6',
          'emp_sultana',
          staff,
          'Let’s review the follow-up plan after lunch.',
          const Duration(minutes: 55)),
      sample(
          'sample_7',
          'emp_hamim',
          staff,
          'Thanks for sharing the client requirements!',
          const Duration(days: 1, minutes: 30)),
    ]
        .where((message) =>
            EmployeeStore.instance.byId(message.senderId) != null &&
            EmployeeStore.instance.byId(message.recipientId) != null)
        .toList();
  }
}
