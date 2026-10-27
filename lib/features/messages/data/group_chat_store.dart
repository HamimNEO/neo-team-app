import 'dart:async';
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/services/demo_session.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../more/data/notification_store.dart';
import '../../settings/data/profile_store.dart';
import '../../team/data/department_store.dart';
import '../../team/data/employee_store.dart';
import '../../team/data/team_store.dart';
import '../../team/domain/models/employee.dart';
import '../domain/group_chat_access.dart';
import '../domain/models/chat_attachment.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/group_chat.dart';
import 'attachment_storage.dart';
import 'group_chat_cache.dart';
import 'message_api.dart';
import 'message_store.dart';

/// Live Group Chat Store for Teams and Departments connected to backend API.
class GroupChatStore extends FrameSafeNotifier {
  GroupChatStore._() {
    _token = _session.accessToken;
    DemoSession.instance.addListener(() {
      if (_token != _session.accessToken) {
        _token = _session.accessToken;
        _groups = [];
        _seeded = {};
        _memberIds.clear();
        _hydrated = false;
        _loading = null;
        error = null;
      }
      notifyListeners();
    });
    EmployeeStore.instance.addListener(notifyListeners);
    TeamStore.instance.addListener(notifyListeners);
    DepartmentStore.instance.addListener(notifyListeners);
  }

  static final instance = GroupChatStore._();
  final _cache = GroupChatCache();
  final _session = DemoSession.instance;
  List<GroupChat> _groups = [];
  Set<String> _seeded = {};
  Future<void>? _loading;
  Future<void> _pending = Future.value();
  bool _hydrated = false;
  String? error, _token;
  String? mutationWarning;
  final Map<String, List<String>> _memberIds = {};
  final Map<String, Map<String, String>> _memberUserIds = {};

  final MessageApi _api = MessageApi(ApiClient(
    baseUrl: () => AppConfig.apiBaseUrl,
    accessToken: () => AuthSession.instance.accessToken,
  ));

  MessageApi get api => _api;

  List<ChatScope> get scopes {
    if (!_session.signedIn) return const [];
    final result = <String, ChatScope>{};
    void add(ChatScope s) => result[s.key] = s;
    for (final team in TeamStore.instance.teams) {
      add(ChatScope(
          id: team.name,
          name: team.name,
          kind: GroupChatKind.team,
          leadEmployeeId:
              TeamStore.instance.detailFor(team.name)?.team.lead?.id ??
                  team.lead?.id));
    }
    for (final department in DepartmentStore.instance.departments) {
      add(ChatScope(
          id: department.id,
          name: department.name,
          kind: GroupChatKind.department,
          leadEmployeeId: department.leadEmployeeId));
    }
    final me = EmployeeStore.instance.byId(_session.employeeId);
    final employees = [
      ...EmployeeStore.instance.staffEmployees,
      if (me != null) me
    ];
    for (final employee in employees) {
      if (employee.team.isNotEmpty) {
        final scope = ChatScope(
            id: employee.team,
            name: employee.team,
            kind: GroupChatKind.team,
            leadEmployeeId:
                TeamStore.instance.detailFor(employee.team)?.team.lead?.id);
        result.putIfAbsent(scope.key, () => scope);
      }
      if (employee.department.isNotEmpty &&
          !result.values.any((s) =>
              s.kind == GroupChatKind.department &&
              s.name == employee.department)) {
        add(ChatScope(
            id: employee.departmentId ?? employee.department,
            name: employee.department,
            kind: GroupChatKind.department));
      }
    }
    return result.values.where(canParticipate).toList();
  }

  bool canParticipate(ChatScope scope) {
    final me = EmployeeStore.instance.byId(_session.employeeId);
    return GroupChatAccess.canParticipate(scope,
        signedIn: _session.signedIn,
        admin: _session.isAdmin,
        employeeId: _session.employeeId,
        team: me?.team ?? '',
        department: me?.department ?? '',
        departmentId: me?.departmentId);
  }

  bool canManage(ChatScope scope) =>
      canParticipate(scope) &&
      GroupChatAccess.canManage(scope,
          signedIn: _session.signedIn,
          admin: _session.isAdmin,
          employeeId: _session.employeeId);

  ChatScope? scopeFor(GroupChat group) {
    for (final scope in scopes) {
      if (scope.key == group.scopeKey) return scope;
    }
    final parts = group.scopeKey.split(':');
    if (parts.length >= 2) {
      final kind =
          parts[0] == 'team' ? GroupChatKind.team : GroupChatKind.department;
      return ChatScope(
          id: parts[1], name: parts.sublist(1).join(':'), kind: kind);
    }
    return null;
  }

  GroupChat? byId(String id) {
    for (final g in _groups) {
      if (g.id == id && scopeFor(g) != null) return g;
    }
    return null;
  }

  List<GroupChat> get allGroups => List.unmodifiable(_groups);

  List<GroupChat> list(GroupChatKind kind,
      {bool archived = false, bool unreadOnly = false, String query = ''}) {
    final q = query.trim().toLowerCase();
    return _groups.where((g) {
      final scope = scopeFor(g);
      return scope?.kind == kind &&
          isArchived(g) == archived &&
          (!unreadOnly || unreadFor(g) > 0) &&
          '${g.name} ${g.description} ${scope?.name} ${g.messages.lastOrNull?.preview ?? ''}'
              .toLowerCase()
              .contains(q);
    }).toList()
      ..sort((a, b) => (b.messages.lastOrNull?.sentAt ?? b.createdAt)
          .compareTo(a.messages.lastOrNull?.sentAt ?? a.createdAt));
  }

  bool isArchived(GroupChat group) =>
      group.archivedBy.contains(_session.employeeId);

  int unreadFor(GroupChat group) {
    if (scopeFor(group) == null) return 0;
    final through = group.readThrough[_session.employeeId] ?? 0;
    return group.messages
        .where((m) =>
            !m.isDeleted &&
            m.senderId != _session.employeeId &&
            m.sentAt.microsecondsSinceEpoch > through)
        .length;
  }

  int get unreadCount => _groups
      .where((g) => !isArchived(g))
      .fold(0, (count, g) => count + unreadFor(g));

  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    final actor = _session.employeeId, token = _session.accessToken;
    if (!_session.signedIn) return;
    error = null;
    try {
      if (!_hydrated) {
        final cached = await _cache.read();
        if (token != _session.accessToken) return;
        _groups = cached.groups
            .where((g) => !g.id.startsWith('demo_group_'))
            .toList();
        _seeded = cached.seeded;
        _hydrated = true;
      }
      await Future.wait([
        EmployeeStore.instance.load(),
        TeamStore.instance.load(),
        DepartmentStore.instance.load(),
        if (!_session.isAdmin) ProfileStore.instance.load(),
      ]);
      if (actor != _session.employeeId || token != _session.accessToken) return;
      final team = EmployeeStore.instance.byId(actor)?.team;
      if (team != null && team.isNotEmpty) {
        try {
          await TeamStore.instance.details(team);
        } catch (_) {
          /* Fail closed. */
        }
      }
      unawaited(syncRemote());
    } catch (_) {
      if (token == _session.accessToken) {
        error = 'Group chats could not be loaded. Tap Retry.';
      }
    }
    notifyListeners();
  }

  Future<void> syncRemote() async {
    if (!_session.signedIn) return;
    final token = _session.accessToken;
    try {
      final teamResFuture = _api.listConversations(scope: 'team', token: token);
      final deptResFuture =
          _api.listConversations(scope: 'department', token: token);
      final results = await Future.wait([teamResFuture, deptResFuture]);

      final teamConvs = (results[0]['conversations'] as List? ?? []);
      final deptConvs = (results[1]['conversations'] as List? ?? []);
      final allConvs = [...teamConvs, ...deptConvs];

      final updatedGroups = <GroupChat>[];

      for (final c in allConvs) {
        final convId = c['id'].toString();
        try {
          final details = await _api.getConversation(convId, token: token);
          if (token != _session.accessToken) return;
          final participantUserMap = <String, String>{};
          final participantEmpIds = <String>[];
          for (final member in details['participants'] as List? ?? []) {
            if (member is Map) {
              final rawId =
                  member['id']?.toString() ?? member['employee_id']?.toString();
              if (rawId != null) {
                final empKey = 'api_emp_$rawId';
                participantEmpIds.add(empKey);
                final userId = member['user_id']?.toString() ?? rawId;
                participantUserMap[empKey] = userId;
              }
            }
          }
          _memberIds[convId] = participantEmpIds;
          _memberUserIds[convId] = participantUserMap;
          final convData =
              details['conversation'] as Map<String, dynamic>? ?? {};
          final msgs =
              (details['messages'] as List? ?? []).cast<Map<String, dynamic>>();

          final isTeam = (convData['type'] ?? c['type']) == 'team';
          String scopeKey;
          if (isTeam) {
            final teamName =
                convData['team']?.toString() ?? c['team']?.toString() ?? '';
            final matchingScope = scopes
                .where((s) =>
                    s.kind == GroupChatKind.team &&
                    (s.id.toLowerCase() == teamName.toLowerCase() ||
                        s.name.toLowerCase() == teamName.toLowerCase()))
                .firstOrNull;
            scopeKey = matchingScope?.key ?? 'team:$teamName';
          } else {
            final deptName = convData['department']?.toString() ??
                c['department']?.toString() ??
                '';
            final matchingScope = scopes
                .where((s) =>
                    s.kind == GroupChatKind.department &&
                    (s.id == deptName ||
                        s.name.toLowerCase() == deptName.toLowerCase()))
                .firstOrNull;
            scopeKey = matchingScope?.key ?? 'department:$deptName';
          }

          final rawDesc = convData['description']?.toString() ??
              c['description']?.toString() ??
              '';
          String? photoUrl = convData['avatar_url']?.toString();
          final avatarMatch =
              RegExp(r'\[avatar:(https?://[^\]]+)\]').firstMatch(rawDesc);
          if (avatarMatch != null) {
            photoUrl = avatarMatch.group(1);
          }

          final parsedMessages = <ChatMessage>[];
          for (final m in msgs) {
            final body = m['body']?.toString() ?? '';
            final msgAvatarMatch =
                RegExp(r'\[avatar:(https?://[^\]]+)\]').firstMatch(body);
            if (msgAvatarMatch != null) {
              photoUrl ??= msgAvatarMatch.group(1);
              if (body.startsWith('[avatar:') && body.endsWith(']')) {
                continue;
              }
            }
            if (body == '[Group Avatar]') {
              continue;
            }

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

            final existingGroup =
                _groups.where((g) => g.id == convId).firstOrNull;
            final existingMsg =
                existingGroup?.messages.where((em) => em.id == mId).firstOrNull;
            final reactionMap = <String, String>{};
            final rawReactions = m['reactions'];
            if (rawReactions is List) {
              for (final r in rawReactions) {
                if (r is Map && r['emoji'] != null) {
                  final emp = r['employee_id'] != null
                      ? 'api_emp_${r['employee_id']}'
                      : (r['user_id']?.toString() == '1'
                          ? DemoSession.adminEmployeeId
                          : _session.employeeId);
                  reactionMap[emp] = r['emoji'].toString();
                }
              }
            }
            if (existingMsg != null) {
              for (final e in existingMsg.reactions.entries) {
                reactionMap.putIfAbsent(e.key, () => e.value);
              }
            }

            ChatReply? reply;
            final replyToId = m['reply_to_message_id'];
            if (replyToId != null) {
              reply = ChatReply(
                messageId: replyToId.toString(),
                senderId: '',
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

            parsedMessages.add(ChatMessage(
              id: mId,
              senderId: senderId,
              recipientId: convId,
              text: body,
              sentAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              pinnedAt: m['pinned_at'] != null
                  ? DateTime.tryParse(m['pinned_at'].toString())
                  : null,
              isDeleted: m['deleted_at'] != null,
              reactions: reactionMap,
              reply: reply,
              attachments: msgAttachments,
            ));
          }

          final cleanDesc =
              rawDesc.replaceAll(RegExp(r'\s*\[avatar:[^\]]+\]'), '').trim();
          final existing = _groups.where((g) => g.id == convId).firstOrNull;
          final groupChat = GroupChat(
            id: convId,
            scopeKey: scopeKey,
            name: convData['name']?.toString() ??
                c['name']?.toString() ??
                'Group Chat',
            description: cleanDesc,
            photoBase64: existing?.photoBase64,
            photoUrl: photoUrl ?? existing?.photoUrl,
            createdBy: 'admin',
            createdAt:
                DateTime.tryParse(convData['updated_at']?.toString() ?? '') ??
                    DateTime.now(),
            messages: parsedMessages,
            readThrough: existing?.readThrough ?? const {},
            archivedBy:
                convData['is_archived'] == true ? [_session.employeeId] : [],
          );
          updatedGroups.add(groupChat);
        } catch (_) {
          // Ignore individual conversation failure
        }
      }

      if (token != _session.accessToken) return;
      error = null;
      final idSet = updatedGroups.map((g) => g.id).toSet();
      _groups = [
        ..._groups.where((g) =>
            !idSet.contains(g.id) &&
            allConvs.any((c) => c['id'].toString() == g.id)),
        ...updatedGroups,
      ];
      await _cache.save(_groups, _seeded);
      notifyListeners();
    } catch (e) {
      if (token == _session.accessToken) {
        error = e is FormatException
            ? e.message
            : 'Messages could not be refreshed.';
        notifyListeners();
      }
    }
  }

  void _authorize(String actor, String? token) {
    if (!_session.signedIn ||
        actor != _session.employeeId ||
        token != _session.accessToken) {
      throw const FormatException('Your session changed. Reopen Messages.');
    }
  }

  Future<void> _write(
      String actor, String? token, FutureOr<void> Function() update) async {
    final operation = _pending.then((_) async {
      _authorize(actor, token);
      if (!_hydrated) {
        throw const FormatException('Load group chats before making changes.');
      }
      final previous = List<GroupChat>.of(_groups),
          seeded = Set<String>.of(_seeded);
      try {
        await update();
        _authorize(actor, token);
        await _cache.save(_groups, _seeded);
      } catch (_) {
        if (token == _session.accessToken) {
          _groups = previous;
          _seeded = seeded;
        }
        rethrow;
      }
      notifyListeners();
    });
    _pending =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  ChatScope _managementScope(String key) {
    for (final scope in scopes) {
      if (scope.key == key && canManage(scope)) {
        return scope;
      }
    }
    if (_session.isAdmin) {
      final parts = key.split(':');
      if (parts.length >= 2) {
        return ChatScope(
            id: parts[1],
            name: parts.sublist(1).join(':'),
            kind: parts[0] == 'team'
                ? GroupChatKind.team
                : GroupChatKind.department);
      }
    }
    throw const FormatException(
        'Only the administrator or unit lead can manage this group.');
  }

  Future<GroupChat> save(
      {required ChatScope scope,
      GroupChat? group,
      required String name,
      required String description,
      String? photoBase64,
      bool removePhoto = false,
      String? photoUrl}) async {
    final actor = _session.employeeId, token = _session.accessToken;
    mutationWarning = null;
    if (removePhoto && group?.photoUrl != null) {
      throw const FormatException(
          'The API does not document removing an existing group photo yet. You can replace it by selecting a new photo.');
    }
    GroupChat? saved;
    await _write(actor, token, () async {
      _managementScope(scope.key);
      if (name.trim().isEmpty ||
          name.trim().length > 120 ||
          description.trim().length > 1000) {
        throw const FormatException(
            'Use a name of 1-120 characters and a description up to 1,000 characters.');
      }

      final cleanDesc = description.trim();
      String id;
      GroupChat? current;
      if (group != null) {
        current = _require(group.id);
        id = current.id;
        await _api.editGroup(id, {
          'name': name.trim(),
          'description': cleanDesc,
        });
      } else {
        Map<String, dynamic> response;
        if (scope.kind == GroupChatKind.team) {
          response = await _api.createTeamConversation(
              team: scope.id, name: name.trim(), description: cleanDesc);
        } else {
          final departmentId = int.tryParse(scope.id);
          if (departmentId == null) {
            throw const FormatException(
                'Refresh the department directory before creating a group.');
          }
          response = await _api.createDepartmentConversation(
              departmentId: departmentId,
              name: name.trim(),
              description: cleanDesc);
        }
        final raw = response['conversation'];
        if (raw is! Map || raw['id'] == null) {
          throw const FormatException(
              'Group accepted without a conversation ID. Refresh Messages before retrying.');
        }
        id = raw['id'].toString();
      }
      String? uploadedUrl = removePhoto ? null : photoUrl ?? current?.photoUrl;
      try {
        if (photoBase64 != null && photoBase64.isNotEmpty) {
          final response =
              await _api.uploadGroupPhoto(id, base64Decode(photoBase64));
          final raw = response['conversation'];
          uploadedUrl =
              (raw is Map ? raw['avatar_url'] : response['avatar_url'])
                  ?.toString();
          if (uploadedUrl == null) {
            throw const FormatException(
                'Photo accepted. Refresh the conversation to view the updated avatar.');
          }
        }
      } catch (_) {
        if (current != null) rethrow;
        mutationWarning =
            'Group created, but its photo could not be confirmed. Open Group Info to retry the photo upload.';
      }

      saved = current != null
          ? current.copyWith(
              name: name.trim(),
              description: cleanDesc,
              photoUrl: uploadedUrl,
              removePhoto: true,
              removePhotoUrl: removePhoto)
          : GroupChat(
              id: id,
              scopeKey: scope.key,
              name: name.trim(),
              description: cleanDesc,
              photoUrl: uploadedUrl,
              createdBy: actor,
              createdAt: DateTime.now());
      _groups = [..._groups.where((g) => g.id != id), saved!];
    });
    return saved!;
  }

  Future<void> delete(String id) async {
    final actor = _session.employeeId, token = _session.accessToken;
    _managementScope(_require(id).scopeKey);
    await _api.deleteConversation(id);
    List<ChatAttachment> cleanup = [];
    await _write(actor, token, () {
      final group = _require(id);
      _managementScope(group.scopeKey);
      cleanup = group.messages.expand((m) => m.attachments).toList();
      _groups.removeWhere((g) => g.id == id);
    });
    for (final attachment in cleanup) {
      try {
        await AttachmentStorage.remove(attachment);
      } catch (_) {
        /* Metadata already deleted. */
      }
    }
  }

  Future<void> leaveGroup(String id) async {
    final actor = _session.employeeId, token = _session.accessToken;
    await _api.leaveGroup(id, token: token);
    await _write(actor, token, () {
      _groups.removeWhere((g) => g.id == id);
    });
  }

  Future<void> addMember(String id, Employee employee) async {
    _managementScope(_require(id).scopeKey);
    final employeeId = int.tryParse(employee.backendId ?? '');
    if (employeeId == null) {
      throw const FormatException('Choose an employee from the directory.');
    }
    await _api.addMember(id, employeeId);
    await syncRemote();
  }

  Future<void> removeMember(String id, Employee employee) async {
    final group = _require(id);
    _managementScope(group.scopeKey);
    if (employee.id == group.createdBy) {
      throw const FormatException('The group creator cannot be removed.');
    }
    if (employee.id == _session.employeeId) {
      throw const FormatException('Use leave group to remove yourself.');
    }
    final userId = _memberUserIds[id]?[employee.id] ??
        employee.backendId ??
        employee.id.replaceFirst('api_emp_', '');
    await _api.removeGroupMember(id, userId, token: _session.accessToken);
    await syncRemote();
  }

  GroupChat _require(String id) =>
      byId(id) ??
      (throw const FormatException(
          'This group is unavailable or you are no longer a member.'));

  Future<void> _update(String id, GroupChat Function(GroupChat) update) =>
      _write(_session.employeeId, _session.accessToken, () {
        final current = _require(id);
        _groups[_groups.indexWhere((g) => g.id == id)] = update(current);
      });

  Future<void> archive(String id, bool archived) async {
    await _api.archiveConversation(id);
    return _update(id, (g) {
      final owners = [...g.archivedBy]..remove(_session.employeeId);
      if (archived) owners.add(_session.employeeId);
      return g.copyWith(archivedBy: owners);
    });
  }

  Future<void> markRead(String id) => _update(
      id,
      (g) => g.copyWith(readThrough: {
            ...g.readThrough,
            _session.employeeId:
                g.messages.lastOrNull?.sentAt.microsecondsSinceEpoch ?? 0
          }));

  Future<void> markAllRead(GroupChatKind kind, {required bool archived}) =>
      _write(_session.employeeId, _session.accessToken, () {
        for (final group in list(kind, archived: archived)) {
          _groups[_groups.indexWhere((g) => g.id == group.id)] =
              group.copyWith(readThrough: {
            ...group.readThrough,
            _session.employeeId:
                group.messages.lastOrNull?.sentAt.microsecondsSinceEpoch ?? 0
          });
        }
      });

  List<Employee> conversationMembers(GroupChat group) => [
        for (final id in _memberIds[group.id] ?? <String>[])
          if (EmployeeStore.instance.byId(id) != null)
            EmployeeStore.instance.byId(id)!
      ];

  List<Employee> members(ChatScope scope) {
    final current = EmployeeStore.instance.byId(_session.employeeId);
    return {
      for (final employee in [
        ...EmployeeStore.instance.staffEmployees,
        if (current != null && !_session.isAdmin) current
      ])
        if ((scope.leadEmployeeId != null &&
                GroupChatAccess.employeeKey(employee.id) ==
                    GroupChatAccess.employeeKey(scope.leadEmployeeId!)) ||
            (scope.kind == GroupChatKind.team
                ? employee.team == scope.id
                : (employee.departmentId == scope.id ||
                    employee.department == scope.name)))
          employee.id: employee
    }.values.toList();
  }

  String senderName(String id) {
    if (id == DemoSession.adminEmployeeId || id == 'usr_1') {
      return 'Super Admin';
    }
    return EmployeeStore.instance.byId(id)?.name ?? 'Teammate';
  }

  Future<void> react(String id, String messageId, String emoji) async {
    await _api.reactToMessage(messageId, emoji);
    return _update(id, (g) {
      if (!ChatMessage.reactionOptions.contains(emoji)) {
        throw const FormatException('Choose a supported reaction.');
      }
      return g.copyWith(
          messages: g.messages.map((m) {
        if (m.id != messageId || m.isDeleted) return m;
        final reactions = {...m.reactions};
        if (reactions[_session.employeeId] == emoji) {
          reactions.remove(_session.employeeId);
        } else {
          reactions[_session.employeeId] = emoji;
        }
        return m.copyWith(reactions: reactions);
      }).toList());
    });
  }

  Future<void> deleteMessage(String id, String messageId) async {
    await _api.deleteMessage(messageId);
    return _update(
        id,
        (g) => g.copyWith(
                messages: g.messages.map((m) {
              if (m.id != messageId) return m;
              if (m.senderId != _session.employeeId) {
                throw const FormatException(
                    'You can only delete messages you sent.');
              }
              return m.copyWith(
                  isDeleted: true, text: '', clearReply: true, reactions: {});
            }).toList()));
  }

  Future<void> send(String id, String text,
      {List<PendingChatAttachment> attachments = const [],
      String? replyToId}) async {
    final actor = _session.employeeId, token = _session.accessToken;
    final saved = <ChatAttachment>[];
    try {
      await _write(actor, token, () async {
        final group = _require(id), value = text.trim();
        ChatReply? reply;
        if (replyToId != null) {
          final original = group.messages
              .where((m) => m.id == replyToId && !m.isDeleted)
              .firstOrNull;
          if (original == null) {
            throw const FormatException(
                'The message you replied to was deleted.');
          }
          reply = ChatReply(
              messageId: original.id,
              senderId: original.senderId,
              preview: original.preview.length > 300
                  ? original.preview.substring(0, 300)
                  : original.preview);
        }
        if ((value.isEmpty && attachments.isEmpty) || value.length > 4000) {
          throw const FormatException(
              'Add a message or attachment. Maximum text length is 4,000 characters.');
        }
        if (attachments.length > MessageStore.maxAttachmentCount ||
            attachments.any((a) =>
                a.bytes.isEmpty ||
                a.bytes.length > MessageStore.maxAttachmentBytes) ||
            attachments.fold<int>(0, (sum, a) => sum + a.bytes.length) >
                MessageStore.maxTotalBytes) {
          throw const FormatException(
              'Attach up to 5 files within the file-size limit.');
        }
        final outgoing = <ChatMessage>[];
        final uploads = attachments.isEmpty
            ? <PendingChatAttachment?>[null]
            : attachments.cast<PendingChatAttachment?>();
        for (final attachment in uploads) {
          final body = outgoing.isEmpty ? value : '';
          final response = attachment == null
              ? await _api.sendMessage(id, body,
                  replyToMessageId: int.tryParse(replyToId ?? ''), token: token)
              : await _api.sendMessageWithAttachment(
                  id, body, attachment.bytes, attachment.name,
                  replyToMessageId: int.tryParse(replyToId ?? ''),
                  token: token);
          final item = response['item'] ?? response['message'];
          if (item is! Map || item['id'] == null) {
            throw const FormatException(
                'Message accepted without confirmation. Refresh before retrying.');
          }
          final messageId = item['id'].toString(), att = item['attachment'];
          final attached = <ChatAttachment>[];
          if (att is Map && att['url'] != null) {
            attached.add(ChatAttachment(
                id: 'att_$messageId',
                name:
                    att['name']?.toString() ?? attachment?.name ?? 'Attachment',
                size: attachment?.bytes.length ?? 0,
                isImage: att['mime']?.toString().startsWith('image/') ?? false,
                url: att['url'].toString()));
          }
          outgoing.add(ChatMessage(
              id: messageId,
              senderId: actor,
              recipientId: id,
              text: item['body']?.toString() ?? body,
              sentAt: DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              attachments: attached,
              reply: reply));
        }
        _authorize(actor, token);
        final current = _require(id);
        _groups[_groups.indexWhere((g) => g.id == id)] = current.copyWith(
            messages: [...current.messages, ...outgoing],
            archivedBy: [...current.archivedBy]..remove(actor));
      });
      await syncRemote();
      NotificationStore.instance.load(filter: 'all', force: true).ignore();
    } catch (_) {
      for (final attachment in saved) {
        try {
          await AttachmentStorage.remove(attachment);
        } catch (_) {
          /* Retry cleanup later. */
        }
      }
      rethrow;
    }
  }
}
