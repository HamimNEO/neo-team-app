import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum EmployeePhotoSource { gallery, files, camera, remove }

class EmployeePhotoPicker {
  static Future<EmployeePhotoSource?> chooseSource(BuildContext context,
          {required bool hasPhoto}) =>
      showCupertinoModalPopup<EmployeePhotoSource>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: const Text('Employee photo'),
          message: const Text('Choose a clear photo for the profile.'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () =>
                  Navigator.pop(sheetContext, EmployeePhotoSource.gallery),
              child: const Text('Photo Library'),
            ),
            CupertinoActionSheetAction(
              onPressed: () =>
                  Navigator.pop(sheetContext, EmployeePhotoSource.files),
              child: const Text('Choose from Files'),
            ),
            if (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)
              CupertinoActionSheetAction(
                onPressed: () =>
                    Navigator.pop(sheetContext, EmployeePhotoSource.camera),
                child: const Text('Take Photo'),
              ),
            if (hasPhoto)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () =>
                    Navigator.pop(sheetContext, EmployeePhotoSource.remove),
                child: const Text('Remove Photo'),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Cancel'),
          ),
        ),
      );

  static Future<String?> pick(EmployeePhotoSource source) async {
    late Uint8List bytes;
    try {
      if (source == EmployeePhotoSource.files) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null) return null;
        final file = result.files.single;
        if (file.size > 15 * 1024 * 1024) {
          throw const FormatException('Choose an image smaller than 15 MB.');
        }
        final selectedBytes = file.bytes;
        if (selectedBytes == null) {
          throw const FormatException('This image could not be opened.');
        }
        bytes = selectedBytes;
      } else {
        final file = await ImagePicker().pickImage(
          source: source == EmployeePhotoSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (file == null) return null;
        if (await file.length() > 15 * 1024 * 1024) {
          throw const FormatException('Choose an image smaller than 15 MB.');
        }
        bytes = await file.readAsBytes();
      }
    } on PlatformException catch (error) {
      final denied = error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('restricted');
      throw FormatException(denied
          ? 'Allow photo or camera access in device Settings, then try again.'
          : 'The photo picker could not open. Please try another source.');
    }
    return _normalize(bytes);
  }

  static Future<String> _normalize(Uint8List bytes) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final scale =
          math.min(1.0, 512 / math.max(descriptor.width, descriptor.height));
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw const FormatException('Image could not be processed.');
      }
      return base64Encode(
          png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes));
    } catch (_) {
      throw const FormatException(
          'Choose a supported photo such as JPG or PNG.');
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
