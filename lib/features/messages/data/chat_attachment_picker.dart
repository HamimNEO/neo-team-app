import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/models/chat_attachment.dart';
import 'attachment_storage.dart';
import 'message_store.dart';

enum ChatAttachmentSource { gallery, camera, files }

class ChatAttachmentPicker {
  static Future<ChatAttachmentSource?> choose(BuildContext context) =>
      showCupertinoModalPopup<ChatAttachmentSource>(
          context: context,
          builder: (context) => CupertinoActionSheet(
              title: const Text('Add Attachment'),
              actions: [
                CupertinoActionSheetAction(
                    onPressed: () =>
                        Navigator.pop(context, ChatAttachmentSource.gallery),
                    child: const Text('Photo Library')),
                if (kIsWeb ||
                    defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS)
                  CupertinoActionSheetAction(
                      onPressed: () =>
                          Navigator.pop(context, ChatAttachmentSource.camera),
                      child: const Text('Take Photo')),
                CupertinoActionSheetAction(
                    onPressed: () =>
                        Navigator.pop(context, ChatAttachmentSource.files),
                    child: const Text('Choose Files')),
              ],
              cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'))));

  static Future<List<PendingChatAttachment>> pick(
      ChatAttachmentSource source) async {
    try {
      if (source == ChatAttachmentSource.files) {
        final selection = await FilePicker.platform
            .pickFiles(allowMultiple: true, withData: true);
        if (selection == null) return [];
        if (selection.files.length > MessageStore.maxAttachmentCount) {
          throw const FormatException('Choose up to 5 attachments at a time.');
        }
        return selection.files.map((file) {
          if (file.size > MessageStore.maxAttachmentBytes) {
            throw FormatException(
                'Choose files up to ${MessageStore.maxAttachmentBytes ~/ (1024 * 1024)} MB each.');
          }
          final bytes = file.bytes;
          if (bytes == null || bytes.isEmpty) {
            throw const FormatException('This file could not be opened.');
          }
          final extension = (file.extension ?? '').toLowerCase();
          return PendingChatAttachment(
              name: file.name,
              bytes: bytes,
              isImage: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp']
                  .contains(extension));
        }).toList();
      }
      final file = await ImagePicker().pickImage(
          source: source == ChatAttachmentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85);
      if (file == null) return [];
      if (await file.length() > MessageStore.maxAttachmentBytes) {
        throw FormatException(
            'Choose a photo up to ${MessageStore.maxAttachmentBytes ~/ (1024 * 1024)} MB.');
      }
      return [
        PendingChatAttachment(
            name: file.name, bytes: await file.readAsBytes(), isImage: true)
      ];
    } on PlatformException catch (error) {
      final denied = error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('restricted');
      throw FormatException(denied
          ? 'Allow photo or camera access in device Settings, then try again.'
          : 'The attachment picker could not open. Please try again.');
    }
  }

  static Future<bool> export(ChatAttachment attachment) async {
    final bytes = await AttachmentStorage.read(attachment);
    if (kIsWeb) {
      final name = attachment.name.replaceAll(RegExp(r'[/\\]'), '_');
      await XFile.fromData(bytes,
              name: name, mimeType: 'application/octet-stream')
          .saveTo(name);
      return true;
    }
    final mobileOrWeb = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Attachment',
        fileName: attachment.name.replaceAll(RegExp(r'[/\\]'), '_'),
        bytes: mobileOrWeb ? bytes : null);
    if (path == null) return false;
    if (!mobileOrWeb) await AttachmentStorage.writeExport(path, bytes);
    return true;
  }
}
