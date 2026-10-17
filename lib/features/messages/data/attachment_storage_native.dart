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
    try {
      return base64Decode(attachment.inlineData!);
    } catch (_) {
      return Uint8List(0);
    }
  }
  try {
    final file = await _file(attachment.id);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    if (attachment.url != null && attachment.url!.isNotEmpty) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(attachment.url!));
        request.headers.set('User-Agent', 'Mozilla/5.0');
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await response
              .fold<List<int>>([], (prev, elem) => prev..addAll(elem));
          final uint8 = Uint8List.fromList(bytes);
          try {
            await file.writeAsBytes(uint8, flush: true);
          } catch (_) {}
          return uint8;
        }
      } finally {
        client.close();
      }
    }
  } catch (_) {}
  return Uint8List(0);
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
