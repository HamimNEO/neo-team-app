import 'dart:typed_data';
import '../domain/models/chat_attachment.dart';
import 'attachment_storage_web.dart'
    if (dart.library.io) 'attachment_storage_native.dart' as storage;

class AttachmentStorage {
  static Future<ChatAttachment> save(
          PendingChatAttachment pending, String id) =>
      storage.save(pending, id);

  static Future<Uint8List> read(ChatAttachment attachment) =>
      storage.read(attachment);

  static Future<void> remove(ChatAttachment attachment) =>
      storage.remove(attachment);

  static Future<void> writeExport(String path, Uint8List bytes) =>
      storage.writeExport(path, bytes);
}
