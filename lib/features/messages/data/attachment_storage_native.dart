import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../domain/models/chat_attachment.dart';

Future<File> _file(String id) async {
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
    throw const FormatException('Invalid attachment.');
  }
  final root = await getApplicationSupportDirectory();
  final directory = Directory('${root.path}/message_attachments');
  await directory.create(recursive: true);
  return File('${directory.path}/$id');
}

Future<ChatAttachment> save(PendingChatAttachment pending, String id) async {
  final file = await _file(id);
  await file.writeAsBytes(pending.bytes, flush: true);
  return ChatAttachment(
      id: id,
      name: pending.name,
      size: pending.bytes.length,
      isImage: pending.isImage);
}

Future<Uint8List> read(ChatAttachment attachment) async {
  if (attachment.inlineData != null) {
    return base64Decode(attachment.inlineData!);
  }
  final file = await _file(attachment.id);
  if (!await file.exists()) {
    throw const FormatException('This attachment is no longer available.');
  }
  return file.readAsBytes();
}

Future<void> remove(ChatAttachment attachment) async {
  try {
    final file = await _file(attachment.id);
    if (await file.exists()) await file.delete();
  } catch (_) {
    /* Cleanup must not undo a committed message deletion. */
  }
}

Future<void> writeExport(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}
