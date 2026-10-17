import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'file_export_stub.dart' if (dart.library.io) 'file_export_native.dart'
    as storage;

class FileExport {
  static Future<void> save(String filename, Uint8List bytes) async {
    final name = filename.replaceAll(RegExp(r'[/\\]'), '_');
    if (kIsWeb) {
      await XFile.fromData(bytes, name: name).saveTo(name);
      return;
    }
    final mobile = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save attachment',
        fileName: name,
        bytes: mobile ? bytes : null);
    if (!mobile && path != null) await storage.write(path, bytes);
  }
}
