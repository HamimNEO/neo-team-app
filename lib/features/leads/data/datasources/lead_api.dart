import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/lead.dart';

class LeadApi {
  const LeadApi(this._client);

  final ApiClient _client;

  Future<List<Lead>> list(String token,
      {bool admin = true, void Function()? onFallback}) async {
    try {
      return await _list(token, admin: admin);
    } on ApiException catch (error) {
      if (admin || (error.statusCode ?? 0) < 500) rethrow;
      final options =
          await _client.get(ApiEndpoints.workItemOptions, token: token);
      final related = options['related_leads'];
      if (related is! List) rethrow;
      final ids = related
          .whereType<Map>()
          .map((m) => m['id']?.toString())
          .whereType<String>()
          .toSet();
      final leads = await Future.wait(ids.map((id) async {
        final response = await getDetails(token, id);
        final raw = response['lead'];
        if (raw is! Map) {
          throw const ApiException('The server returned an invalid lead.');
        }
        return Lead.fromApi(Map<String, dynamic>.from(raw));
      }));
      onFallback?.call();
      return leads;
    }
  }

  Future<List<Lead>> _list(String token, {required bool admin}) async {
    final leads = <Lead>[];
    var page = 1;
    var lastPage = 1;
    do {
      final response = await _client.get(
        admin ? ApiEndpoints.leads : ApiEndpoints.staffLeads,
        queryParameters: {
          'per_page': '100',
          'page': '$page',
          if (!admin) 'view': 'all',
          if (!admin) 'sort': 'recently_updated'
        },
        token: token,
      );
      final currentPage = response['current_page'];
      final last = response['last_page'];
      if (currentPage != page || last is! int || last < page) {
        throw const ApiException(
            'The server returned invalid lead pagination.');
      }
      lastPage = last;
      final rawData = response['data'];
      if (rawData is! List) {
        throw const ApiException('The server returned an invalid lead list.');
      }
      for (final item in rawData) {
        if (item is Map) {
          leads.add(Lead.fromApi(Map<String, dynamic>.from(item)));
        }
      }
      page++;
    } while (page <= lastPage);

    return leads;
  }

  Map<String, dynamic> _payload(Map<String, dynamic> body, bool admin) {
    final result = Map<String, dynamic>.from(body);
    if (!admin) {
      result.remove('current_owner_id');
      result.remove('assigned_employee_id');
      result.remove('assignee_employee_id');
    }
    return result;
  }

  Future<Lead> create(String token, Lead lead, {bool admin = true}) async {
    final response = await _client.post(
      admin ? ApiEndpoints.leads : ApiEndpoints.staffLeads,
      token: token,
      body: _payload(lead.toApiPayload(), admin),
    );
    final rawLead = response['lead'];
    if (rawLead is! Map) {
      throw const ApiException('The server returned an invalid lead.');
    }
    return Lead.fromApi(Map<String, dynamic>.from(rawLead));
  }

  Future<Lead> update(String token, String id, Map<String, dynamic> body,
      {bool admin = true}) async {
    final response = await _client.patch(
      admin ? ApiEndpoints.lead(id) : ApiEndpoints.staffLead(id),
      token: token,
      body: _payload(body, admin),
    );
    final rawLead = response['lead'];
    if (rawLead is! Map) {
      throw const ApiException('The server returned an invalid lead.');
    }
    return Lead.fromApi(Map<String, dynamic>.from(rawLead));
  }

  Future<Lead> reassign(String token, String id, String? employeeId) async {
    final body = <String, dynamic>{
      'current_owner_id': employeeId == null
          ? null
          : (int.tryParse(employeeId.replaceFirst('api_emp_', '')) ??
              employeeId.replaceFirst('api_emp_', '')),
    };
    return update(token, id, body);
  }

  Future<Map<String, dynamic>> addNote(
    String token,
    String id,
    String body,
  ) async {
    final response = await _client.post(
      ApiEndpoints.leadNotes(id),
      token: token,
      body: {'body': body},
    );
    return response;
  }

  Future<Map<String, dynamic>> getOptions(String token) async {
    final response = await _client.get(
      ApiEndpoints.leadOptions,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getDetails(String token, String id) async {
    final response = await _client.get(
      ApiEndpoints.staffLead(id),
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> uploadAttachment(
    String token,
    String leadId, {
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {
    final response = await _client.multipart(
      ApiEndpoints.leadAttachments(leadId),
      fields: const {},
      files: [
        ApiUpload(
          field: 'file',
          filename: filename,
          mimeType: mimeType ?? 'application/octet-stream',
          bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        ),
      ],
      token: token,
    );
    return response;
  }

  Future<Uint8List> downloadAttachment(
          String token, String leadId, String attachmentId) =>
      _client.download(ApiEndpoints.leadAttachment(leadId, attachmentId),
          token: token);
}
