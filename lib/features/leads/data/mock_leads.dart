import '../domain/models/lead.dart';
import 'lead_store.dart';

List<Lead> get mockLeads => LeadStore.instance.leads;

Lead getLeadById(String id) => mockLeads.firstWhere((l) => l.id == id,
    orElse: () => throw StateError('Lead not found'));
