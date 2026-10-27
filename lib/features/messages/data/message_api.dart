import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class MessageApi {
  const MessageApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> listConversations(
      {String scope = 'direct', String status = 'all', String? token}) {
    return _client.get(
      ApiEndpoints.messages,
      queryParameters: {
        'scope': scope,
        'status': status,
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> createDirectConversation(
      int? recipientEmployeeId,
      {String? recipientUserId,
      String? token}) {
    return _client.post(
      ApiEndpoints.messages,
      body: {
        'type': 'direct',
        if (recipientUserId != null) 'recipient_user_id': recipientUserId,
        if (recipientUserId == null && recipientEmployeeId != null)
          'recipient_employee_id': recipientEmployeeId,
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> createTeamConversation({
    required String team,
    required String name,
    String? description,
    String? token,
  }) {
    return _client.post(
      ApiEndpoints.messages,
      body: {
        'type': 'team',
        'team': team,
        'name': name,
        if (description != null) 'description': description,
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> createDepartmentConversation({
    required int departmentId,
    required String name,
    String? description,
    String? token,
  }) {
    return _client.post(
      ApiEndpoints.messages,
      body: {
        'type': 'department',
        'department_id': departmentId,
        'name': name,
        if (description != null) 'description': description,
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> getConversation(String conversationId,
          {String? token}) =>
      _client.get(ApiEndpoints.conversation(conversationId), token: token);

  Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    String body, {
    int? replyToMessageId,
    String? token,
  }) {
    return _client.post(
      ApiEndpoints.sendMessage(conversationId),
      body: {
        'body': body,
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      },
      token: token,
    );
  }

  Future<Map<String, dynamic>> editGroup(
    String conversationId,
    Map<String, dynamic> data, {
    String? token,
  }) {
    return _client.patch(
      ApiEndpoints.conversation(conversationId),
      body: data,
      token: token,
    );
  }

  Future<Map<String, dynamic>> archiveConversation(String conversationId,
          {String? token}) =>
      _client.post(ApiEndpoints.archiveConversation(conversationId),
          token: token);

  Future<Map<String, dynamic>> reactToMessage(String messageId, String emoji,
      {String? token}) {
    return _client.post(
      ApiEndpoints.messageReactions(messageId),
      body: {'emoji': emoji},
      token: token,
    );
  }

  Future<Map<String, dynamic>> pinMessage(String messageId, {String? token}) =>
      _client.post(ApiEndpoints.messagePin(messageId), token: token);

  Future<Map<String, dynamic>> deleteMessage(String messageId,
          {String? token}) =>
      _client.delete(ApiEndpoints.messageItem(messageId), token: token);

  Future<Map<String, dynamic>> uploadGroupPhoto(
    String conversationId,
    Uint8List bytes, {
    String filename = 'group_avatar.png',
    String? token,
  }) {
    return _client.multipart(
      '${ApiEndpoints.conversation(conversationId)}/avatar',
      fields: {},
      files: [
        ApiUpload(
          field: 'avatar',
          bytes: bytes,
          filename: filename,
        ),
      ],
      token: token,
    );
  }

  Future<Map<String, dynamic>> sendMessageWithAttachment(
    String conversationId,
    String text,
    Uint8List bytes,
    String filename, {
    int? replyToMessageId,
    String? token,
  }) {
    return _client.multipart(
      ApiEndpoints.sendMessage(conversationId),
      fields: {
        'body': text.isEmpty ? '[Attachment]' : text,
        if (replyToMessageId != null)
          'reply_to_message_id': replyToMessageId.toString(),
      },
      files: [
        ApiUpload(
          field: 'attachment',
          bytes: bytes,
          filename: filename,
        ),
      ],
      token: token,
    );
  }

  Future<Map<String, dynamic>> deleteConversation(String conversationId,
          {String? token}) =>
      _client.delete(ApiEndpoints.conversation(conversationId), token: token);

  Future<Map<String, dynamic>> leaveGroup(String conversationId,
          {String? token}) =>
      _client.post('${ApiEndpoints.conversation(conversationId)}/leave',
          token: token);

  Future<Map<String, dynamic>> addMember(String conversationId, int employeeId,
          {String? token}) =>
      _client.post('${ApiEndpoints.conversation(conversationId)}/add-member',
          body: {'employee_id': employeeId}, token: token);

  Future<Map<String, dynamic>> removeGroupMember(
          String conversationId, String userId, {String? token}) =>
      _client.delete(ApiEndpoints.removeGroupMember(conversationId, userId),
          token: token);

  Future<Map<String, dynamic>> getRecipients({String? token}) =>
      _client.get(ApiEndpoints.messageRecipients, token: token);
}
