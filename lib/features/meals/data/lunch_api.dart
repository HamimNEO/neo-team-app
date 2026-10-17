import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class LunchApi {
  const LunchApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getMyLunch({String? date, String? token}) {
    final query = <String, String>{if (date != null) 'date': date};
    return _client.get(
      ApiEndpoints.lunchToday,
      queryParameters: query.isNotEmpty ? query : null,
      token: token,
    );
  }

  Future<Map<String, dynamic>> updateMyLunch(
      {required String lunchDate,
      required bool takingLunch,
      String? mealPreference,
      String? note,
      String? token}) {
    return _client.post(
      ApiEndpoints.lunchToggle,
      body: {
        'lunch_date': lunchDate,
        'opt_in': takingLunch,
        if (mealPreference != null) 'meal_preference': mealPreference,
        if (note != null) 'note': note,
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> monthly(String month, {String? token}) =>
      _client.get(ApiEndpoints.lunchMonthly,
          token: token, queryParameters: {'month': month});

  Future<Map<String, dynamic>> roster(String day, {String? token}) =>
      _client.get(ApiEndpoints.lunchRoster,
          token: token, queryParameters: {'date': day});

  Future<Map<String, dynamic>> settings({String? token}) =>
      _client.get(ApiEndpoints.lunchSettings, token: token);

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> body,
          {String? token}) =>
      _client.patch(ApiEndpoints.lunchSettings, token: token, body: body);
}
