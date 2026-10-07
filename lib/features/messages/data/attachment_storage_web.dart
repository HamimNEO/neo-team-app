import 'dart:convert';
import 'dart:typed_data';
import '../domain/models/chat_attachment.dart';

Future<ChatAttachment> save(PendingChatAttachment pending, String id) async =>
    ChatAttachment(
        id: id,
        name: pending.name,
        size: pending.bytes.length,
        isImage: pending.isImage,
        inlineData: base64Encode(pending.bytes));

Future<Uint8List> read(ChatAttachment attachment) async {
  if (attachment.inlineData == null) {
    throw const FormatException(
        'This attachment is unavailable in this browser.');
  }
  return base64Decode(attachment.inlineData!);
}

Future<void> remove(ChatAttachment attachment) async {}

Future<void> writeExport(String path, Uint8List bytes) async {}
