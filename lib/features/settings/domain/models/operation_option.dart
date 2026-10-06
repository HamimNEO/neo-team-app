enum OperationOptionGroup {
  followUpMethods('Methods', 'Method', 'e.g. Video Call'),
  followUpResults('Results', 'Result', 'e.g. Send Brochure'),
  visitPurposes('Purposes', 'Purpose', 'e.g. Site Inspection'),
  visitOutcomes('Outcomes', 'Outcome', 'e.g. Demo Completed');

  final String title;
  final String singular;
  final String placeholder;

  const OperationOptionGroup(this.title, this.singular, this.placeholder);
}

class OperationOption {
  final String name;
  final bool isSystem;
  final bool enabled;

  const OperationOption({
    required this.name,
    this.isSystem = true,
    this.enabled = true,
  });

  OperationOption withEnabled(bool value) => OperationOption(
        name: name,
        isSystem: isSystem,
        enabled: isSystem || value,
      );
}
