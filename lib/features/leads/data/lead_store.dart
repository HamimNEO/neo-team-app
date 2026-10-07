import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';
import '../../team/data/employee_store.dart';
import '../domain/models/lead.dart';
import 'lead_list_seed.dart';
import 'mock_leads.dart';

/// Shared local lead data for the UI demo.
class LeadStore extends ChangeNotifier {
  LeadStore._() : _leads = _seed();
  static final instance = LeadStore._();
  static const _key = 'nec_leads_v1';
  List<Lead> _leads;
  Future<void>? _loading;
  Future<void> _pending = Future<void>.value();
  String? loadError;

  List<Lead> get leads => List.unmodifiable(_leads);

  static List<Lead> _seed() => leadListSeed.map((item) {
        final matching =
            mockLeads.where((lead) => lead.company == item['company']);
        final base =
            matching.isEmpty ? <String, dynamic>{} : matching.first.toJson();
        final subtitle = (item['subtitle'] as String).split(' · ');
        return Lead.fromJson({
          ...base,
          'id': item['id'],
          'company': item['company'],
          'location': subtitle.first,
          'type': subtitle.last,
          'status': item['status'],
          'priority': base['priority'] ?? 'Normal',
          'createdAt': base['createdAt'] ?? DateTime.now().toIso8601String(),
          'assignedEmployeeId':
              item['isMine'] == true ? DemoSession.staffEmployeeId : null,
          'assignedTo': item['assigneeName'] == 'Unassigned'
              ? null
              : item['assigneeName'],
          'scheduleNote': item['scheduleNote'],
          'scheduleGroup': item['group'],
          'overdueSnapshot': item['isOverdue'],
        });
      }).toList();

  Lead? byId(String id) {
    final legacy = RegExp(r'^lead-(\d{3})$').firstMatch(id);
    final canonical = legacy == null ? id : 'lead_${int.parse(legacy[1]!)}';
    for (final lead in _leads) {
      if (lead.id == canonical) return lead;
    }
    return null;
  }

  String assigneeName(Lead lead) =>
      EmployeeStore.instance.byId(lead.assignedEmployeeId ?? '')?.name ??
      lead.assignedTo ??
      'Unassigned';

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        final restored = (jsonDecode(raw) as List)
            .map(
                (item) => Lead.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (restored.map((lead) => lead.id).toSet().length != restored.length) {
          throw const FormatException('Duplicate lead record.');
        }
        _leads = restored;
      }
    } catch (_) {
      loadError =
          'Leads could not be loaded. Restart the app before making changes.';
    }
  }

  void _authorize(String actor, {bool adminOnly = false}) {
    if (loadError != null) throw FormatException(loadError!);
    if (!DemoSession.instance.signedIn ||
        DemoSession.instance.employeeId != actor ||
        (adminOnly && !DemoSession.instance.isAdmin)) {
      throw const FormatException(
          'Administrator access is required to change lead assignments.');
    }
  }

  Future<void> _write(String actor, List<Lead> Function(List<Lead>) update,
      {bool adminOnly = false}) async {
    await load();
    final operation = _pending.then((_) async {
      _authorize(actor, adminOnly: adminOnly);
      final updated = update(List.of(_leads));
      final prefs = await SharedPreferences.getInstance();
      _authorize(actor, adminOnly: adminOnly);
      if (!await prefs.setString(
          _key, jsonEncode(updated.map((lead) => lead.toJson()).toList()))) {
        throw const FormatException(
            'Unable to save this lead. Please try again.');
      }
      _leads = updated;
      notifyListeners();
    });
    _pending =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    await operation;
  }

  void _validateAssignee(String? employeeId) {
    if (employeeId == null) return;
    final employee = EmployeeStore.instance.byId(employeeId);
    if (employee == null || employee.status != 'Active') {
      throw const FormatException('Choose an active employee for this lead.');
    }
  }

  Future<void> save(Lead draft) {
    final actor = DemoSession.instance.employeeId;
    return _write(actor, (leads) {
      final index = leads.indexWhere((lead) => lead.id == draft.id);
      final existing = index < 0 ? null : leads[index];
      final permission = existing == null
          ? StaffPermission.createLead
          : StaffPermission.editLead;
      if (!StaffAccessStore.instance.allows(permission)) {
        throw const FormatException(
            'Your administrator has not enabled this action.');
      }
      if (existing != null &&
          !DemoSession.instance.isAdmin &&
          existing.assignedEmployeeId != actor) {
        throw const FormatException('You can only edit leads assigned to you.');
      }
      // Staff never control assignment, including through the edit form.
      final assignee = DemoSession.instance.isAdmin
          ? draft.assignedEmployeeId
          : existing?.assignedEmployeeId ?? actor;
      _validateAssignee(assignee);
      final saved = Lead.fromJson({
        ...draft.toJson(),
        'assignedEmployeeId': assignee,
        'assignedTo': assignee == null
            ? null
            : EmployeeStore.instance.byId(assignee)!.name,
      });
      if (index < 0) {
        leads.insert(0, saved);
      } else {
        leads[index] = saved;
      }
      return leads;
    });
  }

  Future<void> reassign(String leadId, String? employeeId) {
    final actor = DemoSession.instance.employeeId;
    return _write(actor, (leads) {
      _validateAssignee(employeeId);
      final target = byId(leadId);
      if (target == null) {
        throw const FormatException('This lead is no longer available.');
      }
      final index = leads.indexWhere((lead) => lead.id == target.id);
      leads[index] = Lead.fromJson({
        ...target.toJson(),
        'assignedEmployeeId': employeeId,
        'assignedTo': employeeId == null
            ? null
            : EmployeeStore.instance.byId(employeeId)!.name,
      });
      return leads;
    }, adminOnly: true);
  }
}
