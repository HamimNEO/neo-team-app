import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String _value(String key) =>
      dotenv.isInitialized ? (dotenv.env[key] ?? '').trim() : '';

  static String get apiBaseUrl => _value('API_BASE_URL');

  static String get adminLoginId => _value('ADMIN_LOGIN_ID');

  static String get googleMapsApiKey => _value('GOOGLE_MAPS_API_KEY');
}
