/// Shared aliases for API writes, labels, badges, counts and filters.
class LeadStatus {
  static String api(String value) {
    final key = value.trim().toLowerCase().replaceAll(RegExp(r'[_\-\s]+'), ' ');
    return switch (key) {
      'new lead' || 'new' => 'new',
      'follow up' || 'followup' || 'contacted' => 'contacted',
      'visit scheduled' || 'qualified' => 'qualified',
      _ => key.replaceAll(' ', '_'),
    };
  }

  static String label(String value) => switch (api(value)) {
        'new' => 'New',
        'assigned' => 'Assigned',
        'contacted' => 'Follow-up',
        'interested' => 'Interested',
        'qualified' => 'Visit Scheduled',
        'proposal' => 'Proposal',
        'negotiation' => 'Negotiation',
        'won' => 'Won',
        'lost' => 'Lost',
        final key => key
            .split('_')
            .map(
                (p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
            .join(' '),
      };
}
