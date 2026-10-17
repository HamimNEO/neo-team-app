import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/demo_session.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../team/data/employee_store.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chat_attachment.dart';
import 'attachment_storage.dart';
import 'message_api.dart';

/// Live Direct Messages Store connected to backend with offline-tolerant cache.
class MessageStore extends ChangeNotifier {
  MessageStore._();

  static final instance = MessageStore._();
  static const _key = 'nec_messages_v1';
  List<ChatMessage> _messages = [];
  Map<String, List<String>> _archives = {};
  final Map<String, String> _conversationIdByContact = {};
  Future<void>? _loading;
  Future<void> _pending = Future<void>.value();
  int _sequence = 0;
  String? loadError;

  final MessageApi _api = MessageApi(ApiClient(
    baseUrl: () => AppConfig.apiBaseUrl,
    accessToken: () => AuthSession.instance.accessToken,
  ));

  MessageApi get api => _api;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        final records =
            decoded is List ? decoded : (decoded as Map)['messages'] as List;
        final restored = records
            .map((item) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)))
            .where((m) => !m.id.startsWith('sample_'))
            .toList();
        _messages = restored;
        if (decoded is Map && decoded['archives'] is Map) {
          _archives = (decoded['archives'] as Map).map((owner, contacts) =>
              MapEntry(owner as String, List<String>.from(contacts as List)));
        }
      }
      unawaited(syncRemote());
    } catch (_) {
      loadError = 'Messages could not be loaded. Restart the app to try again.';
    }
  }

  Future<void> syncRemote() async {
    if (!DemoSession.instance.signedIn) return;
    try {
      final res = await _api.listConversations(scope: 'direct');
      final convs = (res['conversations'] as List? ?? []);
      final me = DemoSession.instance.employeeId;
      final myUser = DemoSession.instance.user;
      final myBackendId = myUser?.employeeId.toString() ?? '';

      final existingMap = {for (final m in _messages) m.id: m};
      final newMessages = <ChatMessage>[];

      for (final c in convs) {
        final convId = c['id'].toString();
        try {
          final details = await _api.getConversation(convId);
          final participants = (details['participants'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          final msgs =
              (details['messages'] as List? ?? []).cast<Map<String, dynamic>>();

          String otherEmployeeId = DemoSession.adminEmployeeId;
          if (DemoSession.instance.isAdmin) {
            if (convId == '1') {
              otherEmployeeId = 'api_emp_2';
              _conversationIdByContact['api_emp_2'] = convId;
            } else {
              final target = participants
                      .where((p) => p['id']?.toString() != '2')
                      .firstOrNull ??
                  participants.firstOrNull;
              if (target != null && target['id'] != null) {
                otherEmployeeId = 'api_emp_${target['id']}';
                _conversationIdByContact[otherEmployeeId] = convId;
              }
            }
          } else {
            if (convId == '1') {
              otherEmployeeId = DemoSession.adminEmployeeId;
              _conversationIdByContact[DemoSession.adminEmployeeId] = convId;
              _conversationIdByContact['api_emp_1'] = convId;
            } else {
              final otherPart = participants
                  .where((p) => p['id']?.toString() != myBackendId)
                  .firstOrNull;
              if (otherPart != null && otherPart['id'] != null) {
                otherEmployeeId = 'api_emp_${otherPart['id']}';
                _conversationIdByContact[otherEmployeeId] = convId;
              } else {
                otherEmployeeId = DemoSession.adminEmployeeId;
              }
            }
          }

          for (final m in msgs) {
            final mId = m['id'].toString();
            final senderMap = m['sender'] as Map<String, dynamic>?;
            final senderEmpId = senderMap?['employee_id'];
            final senderUserId = senderMap?['user_id'];
            final senderName = senderMap?['name']?.toString() ?? '';

            String senderId;
            if (senderEmpId != null) {
              senderId = 'api_emp_$senderEmpId';
            } else if (senderName == 'Super Admin' || senderUserId == 1) {
              senderId = DemoSession.adminEmployeeId;
            } else {
              senderId = 'usr_$senderUserId';
            }

            final recipientId = senderId == me ? otherEmployeeId : me;

            final existing = existingMap[mId];
            final reactionMap = <String, String>{};
            final rawReactions = m['reactions'];
            if (rawReactions is List) {
              for (final r in rawReactions) {
                if (r is Map && r['emoji'] != null) {
                  final emp = r['employee_id'] != null
                      ? 'api_emp_${r['employee_id']}'
                      : (r['user_id']?.toString() == '1'
                          ? DemoSession.adminEmployeeId
                          : me);
                  reactionMap[emp] = r['emoji'].toString();
                }
              }
            }
            if (existing != null) {
              for (final e in existing.reactions.entries) {
                reactionMap.putIfAbsent(e.key, () => e.value);
              }
            }

            final readAt = existing?.readAt ??
                (m['read_at'] != null
                    ? DateTime.tryParse(m['read_at'].toString())
                    : null);

            ChatReply? reply;
            final replyToId = m['reply_to_message_id'];
            if (replyToId != null) {
              reply = ChatReply(
                messageId: replyToId.toString(),
                senderId: otherEmployeeId,
                preview: 'Quoted message',
              );
            }

            final rawAtt = m['attachment'] as Map<String, dynamic>?;
            final List<ChatAttachment> msgAttachments = [];
            if (rawAtt != null && rawAtt['url'] != null) {
              msgAttachments.add(ChatAttachment(
                id: 'att_${m['id']}',
                name: rawAtt['name']?.toString() ?? 'image.png',
                size: 0,
                isImage: true,
                url: rawAtt['url'].toString(),
              ));
            }

            newMessages.add(ChatMessage(
              id: mId,
              senderId: senderId,
              recipientId: recipientId,
              text: m['body']?.toString() ?? '',
              sentAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              readAt: readAt,
              pinnedAt: m['pinned_at'] != null
                  ? DateTime.tryParse(m['pinned_at'].toString())
                  : null,
              isDeleted: m['deleted_at'] != null,
              reactions: reactionMap,
              reply: reply,
              attachments: msgAttachments,
            ));
          }
        } catch (_) {
          // Ignore individual conversation failure
        }
      }

      final idSet = newMessages.map((m) => m.id).toSet();
      _messages = [
        ..._messages
            .where((m) => !idSet.contains(m.id) && !m.id.startsWith('sample_')),
        ...newMessages,
      ];
      _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _encode(_messages, _archives));
      notifyListeners();
    } catch (_) {
      // Keep offline cache
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

  String? contactForConversationId(String conversationId) {
    for (final entry in _conversationIdByContact.entries) {
      if (entry.value == conversationId) return entry.key;
    }
    return null;
  }

  String? conversationIdForContact(String employeeId) {
    return _conversationIdByContact[employeeId];
  }

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
      {required bool archived}) async {
    final convId = _conversationIdByContact[employeeId];
    if (convId != null) {
      try {
        await _api.archiveConversation(convId);
      } catch (_) {}
    }
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
        var id = '${me}_${now.microsecondsSinceEpoch}_${_sequence++}';

        String? convId = _conversationIdByContact[employeeId];
        if (convId == null) {
          if (employeeId == DemoSession.adminEmployeeId) {
            convId = _conversationIdByContact['api_emp_1'] ?? '1';
          } else if (employeeId == 'api_emp_2' &&
              DemoSession.instance.isAdmin) {
            convId = '1';
          } else if (employeeId.startsWith('api_emp_')) {
            final bId = int.tryParse(employeeId.substring(8));
            if (bId != null) {
              try {
                final cRes = await _api.createDirectConversation(bId);
                convId = cRes['conversation']?['id']?.toString();
                if (convId != null) {
                  _conversationIdByContact[employeeId] = convId;
                }
              } catch (_) {}
            }
          }
        }

        if (convId != null) {
          try {
            Map<String, dynamic> sent;
            if (attachments.isNotEmpty) {
              final first = attachments.first;
              sent = await _api.sendMessageWithAttachment(
                convId,
                value.isEmpty ? 'Sent an attachment' : value,
                first.bytes,
                first.name,
                replyToMessageId: int.tryParse(replyToId ?? ''),
              );
            } else if (value.isNotEmpty) {
              sent = await _api.sendMessage(
                convId,
                value,
                replyToMessageId: int.tryParse(replyToId ?? ''),
              );
            } else {
              sent = {};
            }
            final item = sent['item'] as Map<String, dynamic>?;
            if (item != null && item['id'] != null) {
              id = item['id'].toString();
              final att = item['attachment'] as Map<String, dynamic>?;
              if (att != null && att['url'] != null) {
                saved.add(ChatAttachment(
                  id: 'att_${item['id']}',
                  name: att['name']?.toString() ?? 'image.png',
                  size: 0,
                  isImage: true,
                  url: att['url'].toString(),
                ));
              }
            }
          } catch (_) {}
        }

        if (saved.isEmpty) {
          for (var index = 0; index < attachments.length; index++) {
            saved.add(await AttachmentStorage.save(
                attachments[index], '${id}_$index'));
          }
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

  Future<void> react(String id, String emoji) async {
    try {
      await _api.reactToMessage(id, emoji);
    } catch (_) {}
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

  Future<void> togglePin(String id) async {
    try {
      await _api.pinMessage(id);
    } catch (_) {}
    return _updateMessage(
        id,
        (message) => message.copyWith(
            pinnedAt: message.pinnedAt == null ? DateTime.now() : null,
            unpin: message.pinnedAt != null));
  }

  Future<void> deleteMessage(String id, {required bool forEveryone}) async {
    if (forEveryone) {
      try {
        await _api.deleteMessage(id);
      } catch (_) {}
    }
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
}
