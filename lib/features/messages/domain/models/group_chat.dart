import 'chat_message.dart';

enum GroupChatKind { team, department }

class ChatScope {
  const ChatScope(
      {required this.id,
      required this.name,
      required this.kind,
      this.leadEmployeeId});

  final String id, name;
  final GroupChatKind kind;
  final String? leadEmployeeId;

  String get key => '${kind.name}:$id';

  String get label => kind == GroupChatKind.team ? 'Team' : 'Department';
}

class GroupChat {
  const GroupChat(
      {required this.id,
      required this.scopeKey,
      required this.name,
      required this.description,
      required this.createdBy,
      required this.createdAt,
      this.photoBase64,
      this.photoUrl,
      this.messages = const [],
      this.readThrough = const {},
      this.archivedBy = const []});

  final String id, scopeKey, name, description, createdBy;
  final DateTime createdAt;
  final String? photoBase64;
  final String? photoUrl;
  final List<ChatMessage> messages;

  final Map<String, int> readThrough;
  final List<String> archivedBy;

  GroupChat copyWith(
          {String? name,
          String? description,
          String? photoBase64,
          bool removePhoto = false,
          String? photoUrl,
          bool removePhotoUrl = false,
          List<ChatMessage>? messages,
          Map<String, int>? readThrough,
          List<String>? archivedBy}) =>
      GroupChat(
          id: id,
          scopeKey: scopeKey,
          name: name ?? this.name,
          description: description ?? this.description,
          createdBy: createdBy,
          createdAt: createdAt,
          photoBase64: removePhoto ? null : photoBase64 ?? this.photoBase64,
          photoUrl: removePhotoUrl ? null : photoUrl ?? this.photoUrl,
          messages: messages ?? this.messages,
          readThrough: readThrough ?? this.readThrough,
          archivedBy: archivedBy ?? this.archivedBy);

  Map<String, dynamic> toJson() => {
        'id': id,
        'scopeKey': scopeKey,
        'name': name,
        'description': description,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'photoBase64': photoBase64,
        'photoUrl': photoUrl,
        'messages': messages.map((m) => m.toJson()).toList(),
        'readThrough': readThrough,
        'archivedBy': archivedBy
      };

  factory GroupChat.fromJson(Map<String, dynamic> json) => GroupChat(
      id: json['id'] as String,
      scopeKey: json['scopeKey'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      photoBase64: json['photoBase64'] as String?,
      photoUrl: json['photoUrl'] as String?,
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      readThrough: Map<String, int>.from(json['readThrough'] as Map? ?? {}),
      archivedBy: List<String>.from(json['archivedBy'] as List? ?? []));
}
