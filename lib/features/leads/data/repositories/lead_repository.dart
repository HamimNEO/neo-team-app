import 'dart:typed_data';
import '../../domain/models/lead.dart';
import '../datasources/lead_api.dart';
import '../datasources/lead_cache.dart';

class LeadRepository {
  const LeadRepository({
    required LeadApi api,
    required LeadCache cache,
  })  : _api = api,
        _cache = cache;

  final LeadApi _api;
  final LeadCache _cache;

  Future<List<Lead>> list(String token,
          {bool admin = true, void Function()? onFallback}) =>
      _api.list(token, admin: admin, onFallback: onFallback);

  Future<List<Lead>?> readCache(String accountId, {required bool admin}) =>
      _cache.read(accountId, admin: admin);

  Future<void> saveCache(String accountId, List<Lead> items,
          {required bool admin}) =>
      _cache.save(accountId, items, admin: admin);

  Future<Lead> create(String token, Lead lead, {bool admin = true}) =>
      _api.create(token, lead, admin: admin);

  Future<Lead> update(String token, String id, Map<String, dynamic> body,
          {bool admin = true}) =>
      _api.update(token, id, body, admin: admin);

  Future<Lead> reassign(String token, String id, String? employeeId) =>
      _api.reassign(token, id, employeeId);

  Future<Map<String, dynamic>> addNote(String token, String id, String body) =>
      _api.addNote(token, id, body);

  Future<Map<String, dynamic>> getOptions(String token) =>
      _api.getOptions(token);

  Future<Map<String, dynamic>> getDetails(String token, String id) =>
      _api.getDetails(token, id);

  Future<Map<String, dynamic>> uploadAttachment(
    String token,
    String leadId, {
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) =>
      _api.uploadAttachment(
        token,
        leadId,
        filename: filename,
        bytes: bytes,
        mimeType: mimeType,
      );

  Future<Uint8List> downloadAttachment(
          String token, String leadId, String attachmentId) =>
      _api.downloadAttachment(token, leadId, attachmentId);
}
