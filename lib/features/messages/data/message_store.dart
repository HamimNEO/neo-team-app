import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:async';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../more/data/notification_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/demo_session.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../team/data/employee_store.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chat_attachment.dart';
import 'attachment_storage.dart';
import 'message_api.dart';

/// Live Direct Messages Store connected to backend with offline-tolerant cache.
class MessageStore extends FrameSafeNotifier {
  MessageStore._() {
    _token = AuthSession.instance.accessToken;
    AuthSession.instance.addListener(() {
      final next = AuthSession.instance.accessToken;
      if (next == _token) return;
      _token = next;
      _messages = [];
      _archives = {};
      _conversationIdByContact.clear();
      _userIdByContact.clear();
      _loading = null;
      loadError = null;
      notifyListeners();
    });
  }

  String? _token;

  static final instance = MessageStore._();

  String get _key =>
      'nec_messages_api_v3_${AuthSession.instance.user?.id ?? 'signed_out'}';
  List<ChatMessage> _messages = [];
  Map<String, List<String>> _archives = {};
  final Map<String, String> _conversationIdByContact = {};
  Future<void>? _loading;
  Future<void> _pending = Future<void>.value();
  final Map<String, String> _userIdByContact = {};
  final Map<String, String> _contactByUserId = {};
  String? loadError;
  bool _isSyncing = false;
  DateTime? _lastRecipientsFetch;

  final MessageApi _api = MessageApi(ApiClient(
    baseUrl: () => AppConfig.apiBaseUrl,
    accessToken: () => AuthSession.instance.accessToken,
  ));

  MessageApi get api => _api;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final token = _token, key = _key;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != _token) return;
      final raw = prefs.getString(key);
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
        notifyListeners();
      }
      unawaited(syncRemote());
    } catch (_) {
      loadError = 'Messages could not be loaded. Restart the app to try again.';
    }
  }

  Future<void> _fetchRecipients(String? token, {bool force = false}) async {
    if (!force &&
        _lastRecipientsFetch != null &&
        DateTime.now().difference(_lastRecipientsFetch!).inMinutes < 5 &&
        _userIdByContact.isNotEmpty) {
      return;
    }
    try {
      final res = await _api.getRecipients(token: token);
      _lastRecipientsFetch = DateTime.now();
      final list = res['recipients'];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            final userId = (item['user_id'] ?? item['id'])?.toString();
            final empId = item['employee_id']?.toString();
            final role = item['role']?.toString();
            final type = item['recipient_type']?.toString();
            final name = item['name']?.toString() ?? '';
            if (userId != null) {
              if (empId != null) {
                _userIdByContact['api_emp_$empId'] = userId;
                _contactByUserId[userId] = 'api_emp_$empId';
              }
              if (role == 'SUPER_ADMIN' ||
                  type == 'administrator' ||
                  name.toLowerCase().contains('admin') ||
                  role?.contains('ADMIN') == true) {
                _userIdByContact[DemoSession.adminEmployeeId] = userId;
                _contactByUserId[userId] = DemoSession.adminEmployeeId;
                _contactByUserId['1'] = DemoSession.adminEmployeeId;
                _contactByUserId['usr_1'] = DemoSession.adminEmployeeId;
              }
              if (item['id'] != null) {
                final rawIdStr = item['id'].toString();
                _userIdByContact[rawIdStr] = userId;
                if (!_contactByUserId.containsKey(rawIdStr)) {
                  _contactByUserId[rawIdStr] = empId != null
                      ? 'api_emp_$empId'
                      : DemoSession.adminEmployeeId;
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> syncRemote() async {
    if (!DemoSession.instance.signedIn || _isSyncing) return;
    _isSyncing = true;
    final token = _token, key = _key;
    try {
      await _fetchRecipients(token);
      final res = await _api.listConversations(scope: 'direct', token: token);
      if (token != _token) return;
      loadError = null;
      final convs = (res['conversations'] as List? ?? []);
      final me = DemoSession.instance.employeeId;
      final myUser = DemoSession.instance.user;
      final myUserIdStr = myUser?.id.replaceFirst('usr_', '') ?? '';
      final myBackendId = myUser?.employeeId.toString() ?? '';

      final existingMap = {for (final m in _messages) m.id: m};

      final detailsResults = await Future.wait(convs.map((c) async {
        final convId = c['id'].toString();
        try {
          final details = await _api.getConversation(convId, token: token);
          return {'conv': c, 'details': details};
        } catch (_) {
          return null;
        }
      }));

      if (token != _token) return;

      final newMessages = <ChatMessage>[];

      for (final pair in detailsResults) {
        if (pair == null) continue;
        final c = pair['conv'] as Map;
        final details = pair['details'] as Map;
        final convId = c['id'].toString();
        final participants = (details['participants'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        final msgs =
            (details['messages'] as List? ?? []).cast<Map<String, dynamic>>();

        String resolveContact(Map p) {
          final role = p['role']?.toString();
          final type = p['recipient_type']?.toString();
          final name = p['name']?.toString() ?? '';
          final uId = (p['user_id'] ?? p['id'])?.toString();
          if (role == 'SUPER_ADMIN' ||
              type == 'administrator' ||
              name.toLowerCase().contains('admin') ||
              uId == '1' ||
              uId == 'usr_1' ||
              _userIdByContact[DemoSession.adminEmployeeId] == uId) {
            return DemoSession.adminEmployeeId;
          }
          if (p['employee_id'] != null) {
            return 'api_emp_${p['employee_id']}';
          }
          final rawId = p['id']?.toString();
          if (rawId != null && !rawId.startsWith('usr_')) {
            final emp = EmployeeStore.instance.byId('api_emp_$rawId') ??
                EmployeeStore.instance.staffEmployees
                    .where((e) => e.backendId == rawId)
                    .firstOrNull;
            if (emp != null) return emp.id;
            return 'api_emp_$rawId';
          }
          return DemoSession.adminEmployeeId;
        }

        bool isMe(Map p) {
          final pUserId = p['user_id']?.toString().replaceFirst('usr_', '');
          final pId = p['id']?.toString().replaceFirst('usr_', '');
          final pEmpId = p['employee_id']?.toString();
          if (DemoSession.instance.isAdmin) {
            final role = p['role']?.toString();
            final name = p['name']?.toString() ?? '';
            return role == 'SUPER_ADMIN' ||
                name == 'Super Admin' ||
                pUserId == '1' ||
                pId == '1' ||
                pUserId == myUserIdStr;
          } else {
            return (myUserIdStr.isNotEmpty && pUserId == myUserIdStr) ||
                (myBackendId.isNotEmpty &&
                    (pId == myBackendId || pEmpId == myBackendId));
          }
        }

        bool isAdminParticipant(Map p) {
          final role = p['role']?.toString();
          final name = p['name']?.toString() ?? '';
          final uId = p['user_id']?.toString().replaceFirst('usr_', '');
          return role == 'SUPER_ADMIN' ||
              name == 'Super Admin' ||
              uId == '1' ||
              p['id']?.toString() == 'usr_1';
        }

        final others = participants.where((p) => !isMe(p)).toList();
        if (others.isEmpty) continue;

        Map<String, dynamic>? target;
        if (others.length == 1) {
          target = others.first;
        } else if (convId == '1') {
          if (DemoSession.instance.isAdmin) {
            target = others.firstWhere(
                (p) =>
                    p['user_id']?.toString() == '66' ||
                    p['id']?.toString() == '2',
                orElse: () => others.first);
          } else {
            target = others.firstWhere((p) => isAdminParticipant(p),
                orElse: () => others.first);
          }
        } else if (!DemoSession.instance.isAdmin) {
          final nonAdmin = others.where((p) => !isAdminParticipant(p)).toList();
          target = nonAdmin.isNotEmpty ? nonAdmin.first : others.first;
        } else {
          final distinctPeer = others.where((p) {
            final uid = p['user_id']?.toString().replaceFirst('usr_', '');
            final empId = p['id']?.toString();
            final name = p['name']?.toString() ?? '';
            return uid != '66' &&
                empId != '2' &&
                uid != '65' &&
                name != 'NEC Onboarding Test';
          }).toList();
          target = distinctPeer.isNotEmpty
              ? distinctPeer.first
              : (others.firstWhere(
                  (p) =>
                      p['user_id']?.toString() == '66' ||
                      p['id']?.toString() == '2',
                  orElse: () => others.first));
        }

        final otherEmployeeId = resolveContact(target);
        _conversationIdByContact[otherEmployeeId] = convId;
        for (final p in participants) {
          final cKey = resolveContact(p);
          final uId = p['user_id']?.toString();
          if (uId != null) {
            _userIdByContact[cKey] = uId;
            _contactByUserId[uId] = cKey;
            _contactByUserId['usr_$uId'] = cKey;
          }
        }

        final archive = _archives.putIfAbsent(me, () => []);
        archive.remove(otherEmployeeId);
        if (c['is_archived'] == true) archive.add(otherEmployeeId);

        for (final m in msgs) {
          final mId = m['id'].toString();
          final senderMap = m['sender'] as Map<String, dynamic>?;
          final senderEmpId = senderMap?['employee_id'];
          final senderUserId =
              (senderMap?['user_id'] ?? m['sender_id'] ?? m['user_id'])
                  ?.toString();
          final senderName = senderMap?['name']?.toString() ?? '';

          String senderId;
          final sUId = senderUserId?.replaceFirst('usr_', '');
          if (senderName == 'Super Admin' ||
              sUId == '1' ||
              _userIdByContact[DemoSession.adminEmployeeId] == senderUserId) {
            senderId = DemoSession.adminEmployeeId;
          } else if (senderEmpId != null) {
            senderId = 'api_emp_$senderEmpId';
          } else if (senderUserId != null &&
              _contactByUserId[senderUserId] != null) {
            senderId = _contactByUserId[senderUserId]!;
          } else if (senderUserId != null &&
              _userIdByContact[otherEmployeeId] == senderUserId) {
            senderId = otherEmployeeId;
          } else if (senderUserId != null &&
              (senderUserId == myUserIdStr || sUId == myUserIdStr)) {
            senderId = me;
          } else {
            senderId = (senderUserId != null && senderUserId == myUserIdStr)
                ? me
                : otherEmployeeId;
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
                    : (r['user_id']?.toString() == '1' ||
                            r['user_id']?.toString() == 'usr_1'
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
            hiddenFor: existing?.hiddenFor ?? const [],
            pinnedAt: m['pinned_at'] != null
                ? DateTime.tryParse(m['pinned_at'].toString())
                : null,
            isDeleted: m['deleted_at'] != null,
            reactions: reactionMap,
            reply: reply,
            attachments: msgAttachments,
          ));
        }
      }

      if (token != _token) return;
      final pending = _messages.where((m) => m.isPending).toList();
      _messages = [...newMessages, ...pending];
      _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, _encode(_messages, _archives));
      notifyListeners();
    } catch (e) {
      if (token == _token && _messages.isEmpty) {
        loadError = e is FormatException
            ? e.message
            : (e is ApiException
                ? e.message
                : 'Messages could not be refreshed.');
        notifyListeners();
      }
    } finally {
      _isSyncing = false;
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
    final token = _token, key = _key;
    await load();
    final operation = _pending.then((_) async {
      _authorize(actorId);
      if (token != _token) throw const FormatException('Your session changed.');
      final updated = await update(List.of(_messages));
      final archives = _archives
          .map((owner, contacts) => MapEntry(owner, List<String>.of(contacts)));
      updateArchives?.call(archives);
      final prefs = await SharedPreferences.getInstance();
      _authorize(actorId);
      if (token != _token) throw const FormatException('Your session changed.');
      if (!await prefs.setString(key, _encode(updated, archives))) {
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
      await _api.archiveConversation(convId);
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
    if (employeeId == me || EmployeeStore.instance.byId(employeeId) == null) {
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
      final original = _target(_messages, replyToId, me);
      if (!original.isBetween(me, employeeId)) {
        throw const FormatException('Reply to a message in this conversation.');
      }
      reply = ChatReply(
          messageId: original.id,
          senderId: original.senderId,
          preview: original.preview.length > 300
              ? original.preview.substring(0, 300)
              : original.preview);
    }

    final tempId =
        'temp_${DateTime.now().millisecondsSinceEpoch}_${_messages.length}';
    final now = DateTime.now();

    final optimisticAttachments = attachments.asMap().entries.map((entry) {
      final i = entry.key;
      final a = entry.value;
      return ChatAttachment(
        id: 'temp_att_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: a.name,
        size: a.bytes.length,
        isImage: a.isImage,
        inlineData: a.isImage && a.bytes.length < 500 * 1024
            ? base64Encode(a.bytes)
            : null,
      );
    }).toList();

    final optimisticMessage = ChatMessage(
      id: tempId,
      senderId: me,
      recipientId: employeeId,
      text: value,
      sentAt: now,
      attachments: List.unmodifiable(optimisticAttachments),
      reply: reply,
      isPending: true,
    );

    _messages.add(optimisticMessage);
    notifyListeners();

    final saved = <ChatAttachment>[];
    try {
      var convId = _conversationIdByContact[employeeId];
      if (convId == null) {
        var userId = _userIdByContact[employeeId];
        if (userId == null) {
          await _fetchRecipients(DemoSession.instance.accessToken);
          userId = _userIdByContact[employeeId];
        }
        if (employeeId == DemoSession.adminEmployeeId) {
          userId ??= 'usr_1';
        }
        final recipient = EmployeeStore.instance.byId(employeeId);
        final backendId = recipient?.backendId ??
            int.tryParse(employeeId.replaceFirst('api_emp_', ''))?.toString();
        if (backendId == null && userId == null) {
          throw const FormatException(
              'The server has not returned this recipient’s user ID. Refresh Messages and try again.');
        }
        final response = await _api.createDirectConversation(
            int.tryParse(backendId ?? ''),
            recipientUserId: userId ?? backendId);
        convId = (response['conversation'] as Map?)?['id']?.toString();
        if (convId == null) {
          throw const FormatException(
              'The server did not confirm this conversation. Refresh Messages before retrying.');
        }
        _conversationIdByContact[employeeId] = convId;
      }
      String? id;
      final uploads = attachments.isEmpty
          ? <PendingChatAttachment?>[null]
          : attachments.cast<PendingChatAttachment?>();
      for (final attachment in uploads) {
        final sent = attachment == null
            ? await _api.sendMessage(convId, value,
                replyToMessageId: int.tryParse(replyToId ?? ''))
            : await _api.sendMessageWithAttachment(convId,
                id == null ? value : '', attachment.bytes, attachment.name,
                replyToMessageId: int.tryParse(replyToId ?? ''));
        final item = sent['item'] ?? sent['message'];
        if (item is! Map || item['id'] == null) {
          throw const FormatException(
              'Message accepted but confirmation was incomplete. Refresh Messages before retrying.');
        }
        id = item['id'].toString();
        final att = item['attachment'];
        if (att is Map && att['url'] != null) {
          saved.add(ChatAttachment(
              id: 'att_$id',
              name: att['name']?.toString() ?? attachment?.name ?? 'Attachment',
              size: attachment?.bytes.length ?? 0,
              isImage: (att['mime']?.toString() ?? '').startsWith('image/'),
              url: att['url'].toString()));
        }
      }

      if (saved.isEmpty && attachments.isNotEmpty) {
        for (var index = 0; index < attachments.length; index++) {
          saved.add(
              await AttachmentStorage.save(attachments[index], '${id}_$index'));
        }
      }

      final confirmed = ChatMessage(
        id: id!,
        senderId: me,
        recipientId: employeeId,
        text: value,
        sentAt: DateTime.now(),
        attachments: List.unmodifiable(saved),
        reply: reply,
        isPending: false,
      );

      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        _messages[idx] = confirmed;
      } else {
        _messages.add(confirmed);
      }
      _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _encode(_messages, _archives));
      notifyListeners();

      unawaited(syncRemote());
      NotificationStore.instance.load(filter: 'all', force: true).ignore();
    } catch (_) {
      _messages.removeWhere((m) => m.id == tempId);
      notifyListeners();
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
    await _api.reactToMessage(id, emoji);
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
    await _api.pinMessage(id);
    return _updateMessage(
        id,
        (message) => message.copyWith(
            pinnedAt: message.pinnedAt == null ? DateTime.now() : null,
            unpin: message.pinnedAt != null));
  }

  Future<void> deleteMessage(String id, {required bool forEveryone}) async {
    if (forEveryone) {
      await _api.deleteMessage(id);
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
