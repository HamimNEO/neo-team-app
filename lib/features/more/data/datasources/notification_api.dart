import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class NotificationApi {
  const NotificationApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> list(
    String token, {
    String filter = 'all',
    int perPage = 30,
    int page = 1,
  }) async {
    final response = await _client.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'filter': filter,
        'per_page': perPage.toString(),
        'page': page.toString(),
      },
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> markAsRead(String token, String id) async {
    final response = await _client.patch(
      ApiEndpoints.markNotificationRead(id),
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> markAllAsRead(String token) async {
    final response = await _client.post(
      ApiEndpoints.markAllNotificationsRead,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getPreferences(String token) async {
    final response = await _client.get(
      ApiEndpoints.pushNotificationPreferences,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> updatePreferences(
    String token, {
    Map<String, dynamic>? categories,
    Map<String, dynamic>? events,
  }) async {
    final body = <String, dynamic>{
      if (categories != null) 'categories': categories,
      if (events != null) 'events': events,
    };
    final response = await _client.put(
      ApiEndpoints.pushNotificationPreferences,
      token: token,
      body: body,
    );
    return response;
  }

  Future<Map<String, dynamic>> registerPushDevice(
    String token, {
    required String fcmToken,
    String? deviceId,
    String? platform,
    String? appVersion,
  }) async {
    final body = <String, dynamic>{
      'fcm_token': fcmToken,
      if (deviceId != null) 'device_id': deviceId,
      if (platform != null) 'platform': platform,
      if (appVersion != null) 'app_version': appVersion,
    };
    final response = await _client.post(
      ApiEndpoints.pushDevices,
      token: token,
      body: body,
    );
    return response;
  }

  Future<Map<String, dynamic>> removePushDevice(
    String token, {
    required String fcmToken,
  }) async {
    final body = <String, dynamic>{
      'fcm_token': fcmToken,
    };
    final response = await _client.delete(
      ApiEndpoints.pushDevices,
      token: token,
      body: body,
    );
    return response;
  }
}
