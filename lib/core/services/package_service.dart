import 'package:package_info_plus/package_info_plus.dart';

class PackageService {
  static PackageInfo? _packageInfo;

  static Future<void> init() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {}
  }

  static String get version {
    if (_packageInfo != null && _packageInfo!.version.isNotEmpty) {
      return _packageInfo!.version;
    }
    return '2.0.0';
  }

  static String get buildNumber {
    if (_packageInfo != null && _packageInfo!.buildNumber.isNotEmpty) {
      return _packageInfo!.buildNumber;
    }
    return '2026.1';
  }
}
