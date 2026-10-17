import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/account_profile.dart';
import '../../../team/domain/models/employee.dart';
import '../profile_api_mapper.dart';

class ProfileApi {
  const ProfileApi(this._client);

  final ApiClient _client;

  Future<AccountProfile> fetch(String token) async {
    final data = await _client.get(ApiEndpoints.profile, token: token);
    if (data['profile'] is! Map) {
      throw const ApiException('The server returned an invalid profile.');
    }
    return accountProfileFromApi(data, AppConfig.apiBaseUrl);
  }

  Future<void> update(String token, Employee employee, {String? photo}) async {
    final body = <String, dynamic>{
      'name': employee.name,
      'phone': employee.phone,
      'address': employee.address,
      'date_of_birth':
          employee.dateOfBirth.isEmpty ? null : employee.dateOfBirth,
      'emergency_contact_name': employee.emergencyContactName,
      'emergency_contact_phone': employee.emergencyContactPhone,
    };
    if (photo == null) {
      await _client.patch(ApiEndpoints.profile, token: token, body: body);
    } else {
      await _client.multipart(ApiEndpoints.profile, token: token, fields: {
        '_method': 'PATCH',
        for (final entry in body.entries)
          entry.key: entry.value?.toString() ?? '',
      }, files: [
        ApiUpload(
            field: 'photo',
            bytes: base64Decode(photo),
            filename: 'profile.png'),
      ]);
    }
  }
}
