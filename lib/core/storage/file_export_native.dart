import 'dart:io';
import 'dart:typed_data';

Future<void> write(String path, Uint8List bytes) =>
    File(path).writeAsBytes(bytes, flush: true);
