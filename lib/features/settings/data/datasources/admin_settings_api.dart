import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class AdminSettingsApi {
  const AdminSettingsApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getAllSettings(String token) async {
    final response = await _client.get(
      ApiEndpoints.adminSettings,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getLeadSettings(String token) async {
    final response = await _client.get(
      ApiEndpoints.adminLeadSettings,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getOperationsSettings(String token) async {
    final response = await _client.get(
      ApiEndpoints.adminOperationsSettings,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getSystemSettings(String token) async {
    final response = await _client.get(
      ApiEndpoints.adminSystemSettings,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> createLeadSource(
    String token, {
    required String key,
    required String label,
    String? color,
  }) async {
    final response = await _client.post(
      '${ApiEndpoints.adminSettings}/lead_sources',
      token: token,
      body: {
        'key': key,
        'label': label,
        if (color != null) 'color': color,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> createCustomField(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      '${ApiEndpoints.adminSettings}/custom_fields',
      token: token,
      body: body,
    );
    return response;
  }

  Future<Map<String, dynamic>> updateSetting(
    String token, {
    required String group,
    required String key,
    required Map<String, dynamic> value,
  }) async {
    final response = await _client.patch(
      '${ApiEndpoints.adminSettings}/$group/$key',
      token: token,
      body: {'value': value},
    );
    return response;
  }

  Future<Map<String, dynamic>> disableLeadSource(
    String token,
    String key, {
    required bool active,
  }) async {
    final response = await _client.patch(
      '${ApiEndpoints.adminSettings}/lead_sources/$key',
      token: token,
      body: {'is_active': active},
    );
    return response;
  }

  Future<Map<String, dynamic>> deleteCustomSetting(
    String token, {
    required String group,
    required String key,
  }) async {
    final response = await _client.delete(
      '${ApiEndpoints.adminSettings}/$group/$key',
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getAdministrationSummary(String token) async {
    final response = await _client.get(
      ApiEndpoints.administration,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getRoles(String token) async {
    final response = await _client.get(
      ApiEndpoints.roles,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getPermissionCatalog(String token) =>
      _client.get(ApiEndpoints.permissionCatalog, token: token);

  Future<Map<String, dynamic>> getRoleDetail(
      String token, String roleId) async {
    final response = await _client.get(
      ApiEndpoints.role(roleId),
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> createRole(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      ApiEndpoints.roles,
      token: token,
      body: body,
    );
    return response;
  }

  Future<Map<String, dynamic>> updateRole(
    String token,
    String roleId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      ApiEndpoints.role(roleId),
      token: token,
      body: body,
    );
    return response;
  }
}
