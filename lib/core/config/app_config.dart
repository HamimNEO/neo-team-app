import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String defaultApiBaseUrl = 'https://api.bingi.com.bd/api';
  static const String defaultAdminLoginId = 'dragon@bingi.com.bd';
  static const String defaultGoogleMapsApiKey =
      'AIzaSyD4ESq0EKqJla2jWBx60SpCJCmN9tiEY2s';

  static String _value(String key, String fallback) {
    if (key == 'API_BASE_URL' && const bool.hasEnvironment('API_BASE_URL')) {
      final envVal = const String.fromEnvironment('API_BASE_URL').trim();
      if (envVal.isNotEmpty) return envVal;
    } else if (key == 'ADMIN_LOGIN_ID' &&
        const bool.hasEnvironment('ADMIN_LOGIN_ID')) {
      final envVal = const String.fromEnvironment('ADMIN_LOGIN_ID').trim();
      if (envVal.isNotEmpty) return envVal;
    } else if (key == 'GOOGLE_MAPS_API_KEY' &&
        const bool.hasEnvironment('GOOGLE_MAPS_API_KEY')) {
      final envVal = const String.fromEnvironment('GOOGLE_MAPS_API_KEY').trim();
      if (envVal.isNotEmpty) return envVal;
    }
    if (dotenv.isInitialized) {
      final dotVal = (dotenv.env[key] ?? '').trim();
      if (dotVal.isNotEmpty) return dotVal;
    }
    return fallback;
  }

  static String get apiBaseUrl => _value('API_BASE_URL', defaultApiBaseUrl);

  static String get adminLoginId =>
      _value('ADMIN_LOGIN_ID', defaultAdminLoginId);

  static String get googleMapsApiKey =>
      _value('GOOGLE_MAPS_API_KEY', defaultGoogleMapsApiKey);
}
