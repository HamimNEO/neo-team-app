import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures real device metadata only when the employee clocks in/out.
class AttendanceContext {
  static Future<Map<String, dynamic>> collect() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('nec_attendance_device_id_v1');
    if (id == null) {
      final random = Random.secure();
      id = List.generate(
              16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();
      await prefs.setString('nec_attendance_device_id_v1', id);
    }
    final result = <String, dynamic>{'device_id': id};
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 12)));
          result.addAll({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy
          });
        }
      }
    } catch (_) {
      // Location is optional in the contract; let the server enforce its policy.
    }
    if (!kIsWeb) {
      try {
        final ssid =
            (await NetworkInfo().getWifiName())?.replaceAll('"', '').trim();
        if (ssid != null && ssid.isNotEmpty && ssid != '<unknown ssid>') {
          result['wifi_ssid'] = ssid;
        }
      } catch (_) {}
    }
    return result;
  }
}
