import 'dart:typed_data';

class PendingChatAttachment {
  final String name;
  final Uint8List bytes;
  final bool isImage;

  const PendingChatAttachment(
      {required this.name, required this.bytes, required this.isImage});
}

class ChatAttachment {
  final String id;
  final String name;
  final int size;
  final bool isImage;
  final String? inlineData;

  const ChatAttachment(
      {required this.id,
      required this.name,
      required this.size,
      required this.isImage,
      this.inlineData});

  String get sizeLabel => size < 1024
      ? '$size B'
      : size < 1024 * 1024
          ? '${(size / 1024).toStringAsFixed(1)} KB'
          : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'isImage': isImage,
        if (inlineData != null) 'inlineData': inlineData
      };

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    final item = ChatAttachment(
        id: json['id'] as String,
        name: json['name'] as String,
        size: json['size'] as int,
        isImage: json['isImage'] as bool,
        inlineData: json['inlineData'] as String?);
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(item.id) ||
        item.size < 0 ||
        item.name.isEmpty) {
      throw const FormatException('Invalid attachment.');
    }
    return item;
  }
}
