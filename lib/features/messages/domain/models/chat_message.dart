import 'chat_attachment.dart';

class ChatReply {
  final String messageId;
  final String senderId;
  final String preview;

  const ChatReply(
      {required this.messageId, required this.senderId, required this.preview});

  Map<String, dynamic> toJson() =>
      {'messageId': messageId, 'senderId': senderId, 'preview': preview};

  factory ChatReply.fromJson(Map<String, dynamic> json) => ChatReply(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      preview: json['preview'] as String);
}

class ChatMessage {
  static const reactionOptions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final DateTime sentAt;
  final DateTime? readAt;
  final List<ChatAttachment> attachments;
  final ChatReply? reply;
  final Map<String, String> reactions;
  final DateTime? pinnedAt;
  final bool isDeleted;
  final List<String> hiddenFor;
  final bool isPending;

  const ChatMessage(
      {required this.id,
      required this.senderId,
      required this.recipientId,
      required this.text,
      required this.sentAt,
      this.readAt,
      this.attachments = const [],
      this.reply,
      this.reactions = const {},
      this.pinnedAt,
      this.isDeleted = false,
      this.hiddenFor = const [],
      this.isPending = false});

  bool involves(String employeeId) =>
      senderId == employeeId || recipientId == employeeId;

  bool isBetween(String first, String second) =>
      (senderId == first && recipientId == second) ||
      (senderId == second && recipientId == first);

  String get preview {
    if (isDeleted) return 'Message deleted';
    final cleaned = text
        .replaceAll(
            RegExp(r'\s*\[\d{1,2}:\d{2}(\s*(?:AM|PM|am|pm))?\]',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'^\s*\[attachment\]\s*$', caseSensitive: false), '')
        .trim();
    if (cleaned.isNotEmpty &&
        (cleaned.toLowerCase() != 'sent an attachment' ||
            attachments.isEmpty)) {
      return cleaned;
    }
    if (attachments.length == 1) {
      return attachments.first.isImage ? 'Photo' : attachments.first.name;
    }
    if (attachments.length > 1) {
      return '${attachments.length} attachments';
    }
    return cleaned.isNotEmpty ? cleaned : 'Message';
  }

  ChatMessage copyWith(
          {String? text,
          DateTime? readAt,
          List<ChatAttachment>? attachments,
          ChatReply? reply,
          bool clearReply = false,
          Map<String, String>? reactions,
          DateTime? pinnedAt,
          bool unpin = false,
          bool? isDeleted,
          List<String>? hiddenFor,
          bool? isPending}) =>
      ChatMessage(
          id: id,
          senderId: senderId,
          recipientId: recipientId,
          text: text ?? this.text,
          sentAt: sentAt,
          readAt: readAt ?? this.readAt,
          attachments: attachments ?? this.attachments,
          reply: clearReply ? null : reply ?? this.reply,
          reactions: reactions ?? this.reactions,
          pinnedAt: unpin ? null : pinnedAt ?? this.pinnedAt,
          isDeleted: isDeleted ?? this.isDeleted,
          hiddenFor: hiddenFor ?? this.hiddenFor,
          isPending: isPending ?? this.isPending);

  ChatMessage markRead(DateTime date) => copyWith(readAt: date);

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'recipientId': recipientId,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
        'attachments':
            attachments.map((attachment) => attachment.toJson()).toList(),
        'reply': reply?.toJson(),
        'reactions': reactions,
        'pinnedAt': pinnedAt?.toIso8601String(),
        'isDeleted': isDeleted,
        'hiddenFor': hiddenFor,
        'isPending': isPending,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final message = ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      text: json['text'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String).toLocal(),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String).toLocal(),
      attachments: List.unmodifiable((json['attachments'] as List? ?? []).map(
          (item) =>
              ChatAttachment.fromJson(Map<String, dynamic>.from(item as Map)))),
      reply: json['reply'] == null
          ? null
          : ChatReply.fromJson(Map<String, dynamic>.from(json['reply'] as Map)),
      reactions: Map.unmodifiable(
          Map<String, String>.from(json['reactions'] as Map? ?? {})),
      pinnedAt: json['pinnedAt'] == null
          ? null
          : DateTime.parse(json['pinnedAt'] as String).toLocal(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      hiddenFor: List.unmodifiable(
          List<String>.from(json['hiddenFor'] as List? ?? [])),
      isPending: json['isPending'] as bool? ?? false,
    );
    if (message.id.isEmpty ||
        message.senderId.isEmpty ||
        message.recipientId.isEmpty ||
        message.senderId == message.recipientId ||
        (!message.isDeleted &&
            message.text.trim().isEmpty &&
            message.attachments.isEmpty)) {
      throw const FormatException('Invalid message record.');
    }
    return message;
  }
}

class MessageThread {
  final String employeeId;
  final ChatMessage lastMessage;
  final int unreadCount;

  const MessageThread(
      {required this.employeeId,
      required this.lastMessage,
      required this.unreadCount});
}
