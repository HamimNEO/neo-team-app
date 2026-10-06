import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionType {
  location,
  camera,
  gallery,
  files,
  notification,
}

class PermissionStatusInfo {
  final AppPermissionType type;
  final String title;
  final String subtitle;
  final Permission permission;
  final bool isGranted;
  final PermissionStatus status;

  const PermissionStatusInfo({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.permission,
    required this.isGranted,
    required this.status,
  });
}

class PermissionService {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  static bool _hasRequestedOnStartup = false;

  /// Requests core native permissions on app startup.
  Future<void> requestInitialPermissions() async {
    if (_hasRequestedOnStartup) return;
    _hasRequestedOnStartup = true;

    try {
      await [
        Permission.notification,
        Permission.locationWhenInUse,
        Permission.camera,
        Permission.photos,
        Permission.storage,
      ].request();
    } catch (e) {
      debugPrint(
          'PermissionService: Initial permission request skipped/failed: $e');
    }
  }

  /// Check whether a permission is granted.
  Future<bool> isGranted(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted || status.isLimited;
    } catch (_) {
      return false;
    }
  }

  /// Get status of all core native permissions.
  Future<Map<AppPermissionType, PermissionStatusInfo>>
      checkAllPermissions() async {
    final results = <AppPermissionType, PermissionStatusInfo>{};

    final definitions = [
      (
        AppPermissionType.location,
        'Location Services',
        'Used to verify site visits and map directions',
        Permission.locationWhenInUse,
      ),
      (
        AppPermissionType.camera,
        'Camera Access',
        'Capture lead photos and task verification images',
        Permission.camera,
      ),
      (
        AppPermissionType.gallery,
        'Photo Gallery',
        'Select attachments and profile pictures from library',
        Permission.photos,
      ),
      (
        AppPermissionType.files,
        'Files & Storage',
        'Save and attach contracts, brochures, and documents',
        Permission.storage,
      ),
      (
        AppPermissionType.notification,
        'Push Notifications',
        'Alerts for scheduled visits, tasks, and team updates',
        Permission.notification,
      ),
    ];

    for (final def in definitions) {
      PermissionStatus status;
      try {
        status = await def.$4.status;
        if (def.$1 == AppPermissionType.gallery &&
            defaultTargetPlatform == TargetPlatform.android) {
          if (!status.isGranted) {
            final storageStatus = await Permission.storage.status;
            if (storageStatus.isGranted) status = PermissionStatus.granted;
          }
        }
      } catch (_) {
        status = PermissionStatus.denied;
      }

      results[def.$1] = PermissionStatusInfo(
        type: def.$1,
        title: def.$2,
        subtitle: def.$3,
        permission: def.$4,
        isGranted: status.isGranted || status.isLimited,
        status: status,
      );
    }

    return results;
  }

  /// Request permission or open system settings if permanently denied or revoking.
  Future<bool> requestOrToggle(Permission permission) async {
    try {
      final current = await permission.status;
      if (current.isGranted || current.isLimited) {
        await openAppSettings();
        final refreshed = await permission.status;
        return refreshed.isGranted || refreshed.isLimited;
      } else {
        final result = await permission.request();
        if (result.isPermanentlyDenied) {
          await openAppSettings();
          final refreshed = await permission.status;
          return refreshed.isGranted || refreshed.isLimited;
        }
        return result.isGranted || result.isLimited;
      }
    } catch (e) {
      debugPrint('PermissionService: requestOrToggle error: $e');
      return false;
    }
  }

  /// Opens native OS app settings directly.
  Future<bool> openNativeSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
