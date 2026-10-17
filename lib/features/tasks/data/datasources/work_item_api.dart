import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../home/domain/models/work_overview.dart';
import '../../domain/models/work_item.dart';

class WorkItemApi {
  const WorkItemApi(this._client);

  final ApiClient _client;

  Map<String, dynamic> _normalize(Map<String, dynamic> response, String? type) {
    final keys = {
      'work_item': type,
      'task': 'task',
      'follow_up': 'followup',
      'followup': 'followup',
      'visit': 'visit',
      'issue': 'issue'
    };
    for (final entry in keys.entries) {
      final raw = response[entry.key];
      if (raw is Map) {
        return {
          ...response,
          'work_item': {
            ...Map<String, dynamic>.from(raw),
            if (raw['type'] == null) 'type': entry.value ?? 'task',
          }
        };
      }
    }
    return response;
  }

  Future<List<WorkItem>> list(String token,
      {bool admin = true, String? type}) async {
    final path = admin ? ApiEndpoints.workItems : ApiEndpoints.staffWorkItems;
    final items = <WorkItem>[];
    var page = 1;
    var lastPage = 1;
    do {
      final query = <String, String>{
        'per_page': '100',
        'page': '$page',
        if (type != null && type.isNotEmpty) 'type': type,
      };
      final response = await _client.get(
        path,
        queryParameters: query,
        token: token,
      );
      final currentPage = response['current_page'];
      final last = response['last_page'];
      if (currentPage != page || last is! int || last < page) {
        throw const ApiException(
            'The server returned invalid work items pagination.');
      }
      lastPage = last;
      final rawData = response['data'];
      if (rawData is! List) {
        throw const ApiException(
            'The server returned an invalid work item list.');
      }
      for (final item in rawData) {
        if (item is Map) {
          items.add(WorkItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      page++;
    } while (page <= lastPage);

    return items;
  }

  Map<String, dynamic> _payload(Map<String, dynamic> body, bool admin) {
    final result = Map<String, dynamic>.from(body);
    if (admin && result['priority'] == 'normal') result['priority'] = 'medium';
    if (!admin && result['priority'] == 'medium') result['priority'] = 'normal';
    if (!admin) result.remove('assignee_employee_id');
    final owner = result['assignee_employee_id'];
    if (owner is String) {
      result['assignee_employee_id'] =
          int.tryParse(owner.replaceFirst('api_emp_', '')) ?? owner;
    }
    return result;
  }

  Future<Map<String, dynamic>> details(
      String token, String id, String type) async {
    final response = await _client.get(
        type == 'visit'
            ? ApiEndpoints.visitDetail(id)
            : type == 'followup'
                ? ApiEndpoints.followUpDetail(id)
                : '${ApiEndpoints.staffWorkItems}/${Uri.encodeComponent(id)}',
        token: token);
    return _normalize(response, type);
  }

  Future<WorkItem> create(String token, Map<String, dynamic> payload,
      {bool admin = true}) async {
    final response = await _client.post(
      admin ? ApiEndpoints.workItems : ApiEndpoints.staffWorkItems,
      token: token,
      body: _payload(payload, admin),
    );
    final rawItem =
        _normalize(response, payload['type']?.toString())['work_item'];
    if (rawItem is! Map) {
      throw const ApiException('The server returned an invalid work item.');
    }
    return WorkItem.fromJson(Map<String, dynamic>.from(rawItem));
  }

  Future<WorkItem> update(String token, String id, Map<String, dynamic> payload,
      {bool admin = true}) async {
    final response = await _client.patch(
      admin
          ? ApiEndpoints.workItem(id)
          : '${ApiEndpoints.staffWorkItems}/${Uri.encodeComponent(id)}',
      token: token,
      body: _payload(payload, admin),
    );
    final rawItem =
        _normalize(response, payload['type']?.toString())['work_item'];
    if (rawItem is! Map) {
      throw const ApiException('The server returned an invalid work item.');
    }
    return WorkItem.fromJson(Map<String, dynamic>.from(rawItem));
  }

  Future<WorkOverview> overview(String token, {bool admin = true}) async {
    final response = await _client.get(
      admin ? ApiEndpoints.overview : ApiEndpoints.staffOverview,
      token: token,
    );
    return WorkOverview.fromJson(response);
  }

  Future<Map<String, dynamic>> completeFollowUp(
    String token,
    String id, {
    required String result,
  }) async {
    final response = await _client.post(
      ApiEndpoints.completeFollowUp(id),
      token: token,
      body: {'result': result},
    );
    return response;
  }

  Future<Map<String, dynamic>> rescheduleFollowUp(
    String token,
    String id, {
    required String date,
    required String time,
  }) async {
    final response = await _client.post(
      ApiEndpoints.rescheduleFollowUp(id),
      token: token,
      body: {'date': date, 'time': time},
    );
    return response;
  }

  Future<Map<String, dynamic>> startVisitJourney(
    String token,
    String id,
  ) async {
    final response = await _client.post(
      ApiEndpoints.startVisitJourney(id),
      token: token,
      body: const {},
    );
    return response;
  }

  Future<Map<String, dynamic>> markVisitArrived(
    String token,
    String id,
  ) async {
    final response = await _client.post(
      ApiEndpoints.markVisitArrived(id),
      token: token,
      body: const {},
    );
    return response;
  }

  Future<Map<String, dynamic>> completeVisitReport(
    String token,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      ApiEndpoints.completeVisitReport(id),
      token: token,
      body: payload,
    );
    return response;
  }

  Future<Map<String, dynamic>> rescheduleVisit(
    String token,
    String id, {
    required String date,
    required String time,
  }) async {
    final response = await _client.post(
      ApiEndpoints.rescheduleVisit(id),
      token: token,
      body: {'date': date, 'time': time},
    );
    return response;
  }

  Future<Map<String, dynamic>> cancelVisit(
    String token,
    String id, {
    required String reason,
  }) async {
    final response = await _client.post(
      ApiEndpoints.cancelVisit(id),
      token: token,
      body: {'reason': reason},
    );
    return response;
  }

  Future<Map<String, dynamic>> addComment(
    String token,
    String id, {
    required String body,
  }) async {
    final response = await _client.post(
      ApiEndpoints.workItemComments(id),
      token: token,
      body: {'body': body},
    );
    return response;
  }

  Future<Map<String, dynamic>> getWorkItemOptions(String token) async {
    final response = await _client.get(
      ApiEndpoints.workItemOptions,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> uploadAttachment(
    String token,
    String workId, {
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {
    final response = await _client.multipart(
      ApiEndpoints.workItemAttachments(workId),
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
          String token, String workId, String attachmentId) =>
      _client.download(ApiEndpoints.workItemAttachment(workId, attachmentId),
          token: token);
}
