import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class AttendanceApi {
  const AttendanceApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getMyAttendance({String? month, String? token}) {
    final query = <String, String>{
      if (month != null) 'month': month,
    };
    return _client.get(
      month == null
          ? ApiEndpoints.attendanceToday
          : ApiEndpoints.attendanceHistory,
      queryParameters: query.isNotEmpty ? query : null,
      token: token,
    );
  }

  Future<Map<String, dynamic>> checkIn(
          {String? token, Map<String, dynamic>? context}) =>
      _client.post(ApiEndpoints.attendanceCheckIn, token: token, body: context);

  Future<Map<String, dynamic>> startBreak({String? token}) =>
      _client.post(ApiEndpoints.attendanceBreakStart, token: token);

  Future<Map<String, dynamic>> endBreak({String? token}) =>
      _client.post(ApiEndpoints.attendanceBreakEnd, token: token);

  Future<Map<String, dynamic>> checkOut(
          {String? token,
          Map<String, dynamic>? context,
          String? summary,
          String? workNotes}) =>
      _client.post(ApiEndpoints.attendanceCheckOut, token: token, body: {
        ...?context,
        if (summary != null) 'summary': summary,
        if (workNotes != null) 'work_notes': workNotes
      });

  Future<Map<String, dynamic>> getRequests(
      {int page = 1, int perPage = 20, String? token}) {
    return _client.get(
      ApiEndpoints.attendanceRequests,
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
      token: token,
    );
  }

  Future<Map<String, dynamic>> submitRequest(Map<String, dynamic> body,
          {String? token}) =>
      _client.post(ApiEndpoints.attendanceRequests, body: body, token: token);

  Future<Map<String, dynamic>> allRequests(
          {required String token, bool admin = false}) async =>
      {
        'data': await _client.all(
            admin
                ? ApiEndpoints.attendanceAdminRequests
                : ApiEndpoints.attendanceRequests,
            token: token),
      };

  Future<Map<String, dynamic>> getAdminOverview({String? date, String? token}) {
    final query = <String, String>{if (date != null) 'date': date};
    return _client.get(
      ApiEndpoints.attendanceAdminOverview,
      queryParameters: query.isNotEmpty ? query : null,
      token: token,
    );
  }

  Future<Map<String, dynamic>> getAdminStaff(
      {String? date,
      String? search,
      int page = 1,
      int perPage = 20,
      String? token}) {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (date != null) 'date': date,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    return _client.get(
      ApiEndpoints.attendanceAdminStaff,
      queryParameters: query,
      token: token,
    );
  }

  Future<Map<String, dynamic>> getAdminEmployeeDetail(String employeeId,
      {String? date, String? token}) {
    final query = <String, String>{if (date != null) 'date': date};
    return _client.get(
      ApiEndpoints.attendanceAdminEmployee(employeeId),
      queryParameters: query.isNotEmpty ? query : null,
      token: token,
    );
  }

  Future<Map<String, dynamic>> manageEmployeeAttendance(
          String employeeId, Map<String, dynamic> body, {String? token}) =>
      _client.put(ApiEndpoints.attendanceAdminEmployee(employeeId),
          body: body, token: token);

  Future<Map<String, dynamic>> getAdminRequests(
      {String status = 'pending',
      int page = 1,
      int perPage = 20,
      String? token}) {
    return _client.get(
      ApiEndpoints.attendanceAdminRequests,
      queryParameters: {
        'status': status,
        'page': '$page',
        'per_page': '$perPage',
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> reviewAdminRequest(
          String requestId, Map<String, dynamic> body, {String? token}) =>
      _client.patch(ApiEndpoints.attendanceAdminReviewRequest(requestId),
          body: body, token: token);

  Future<Map<String, dynamic>> getAdminReports({String? month, String? token}) {
    final query = <String, String>{if (month != null) 'month': month};
    return _client.get(
      ApiEndpoints.attendanceAdminReports,
      queryParameters: query.isNotEmpty ? query : null,
      token: token,
    );
  }

  Future<Map<String, dynamic>> getAdminSettings({String? token}) =>
      _client.get(ApiEndpoints.attendanceAdminSettings, token: token);

  Future<Map<String, dynamic>> updateAdminSettings(Map<String, dynamic> body,
          {String? token}) =>
      _client.put(ApiEndpoints.attendanceAdminSettings,
          body: body, token: token);

  Future<Map<String, dynamic>> addHoliday(Map<String, dynamic> body,
          {String? token}) =>
      _client.post(ApiEndpoints.attendanceAdminHolidays,
          body: body, token: token);

  Future<Map<String, dynamic>> cancelRequest(String id, {String? token}) =>
      _client.delete('${ApiEndpoints.attendanceRequests}/$id', token: token);

  Future<Map<String, dynamic>> revokeOvertime(String id, String reason,
          {String? token}) =>
      _client.post(
          '${ApiEndpoints.attendanceAdminRequests}/$id/revoke-overtime',
          body: {'reason': reason},
          token: token);

  Future<Map<String, dynamic>> updateHoliday(
          String id, Map<String, dynamic> body, {String? token}) =>
      _client.put('${ApiEndpoints.attendanceAdminHolidays}/$id',
          body: body, token: token);

  Future<Map<String, dynamic>> deleteHoliday(String id, {String? token}) =>
      _client.delete('${ApiEndpoints.attendanceAdminHolidays}/$id',
          token: token);

  Future<Map<String, dynamic>> getAdminLunch({String? date, String? token}) {
    final query = <String, String>{if (date != null) 'date': date};
    return _client.get(
      ApiEndpoints.attendanceAdminLunch,
      queryParameters: query.isNotEmpty ? query : null,
      token: token,
    );
  }

  Future<Map<String, dynamic>> manageStaffLunch(
          String employeeId, Map<String, dynamic> body, {String? token}) =>
      _client.put(ApiEndpoints.attendanceAdminManageLunch(employeeId),
          body: body, token: token);
}
