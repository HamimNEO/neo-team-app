class Lead {
  final String id;
  final String company;
  final String type;
  final String location;
  final String status;
  final String priority;
  final String? contactName;
  final String? contactRole;
  final String? phone;
  final String? email;
  final String? source;
  final String? assignedTo;
  final String? nextActionNote;
  final String? currentHms;
  final String? websiteStatus;
  final String? interestedPlan;
  final int? totalProperties;
  final int? totalRooms;
  final List<String> interestedServices;
  final DateTime createdAt;
  final DateTime? nextAction;

  const Lead({
    required this.id,
    required this.company,
    required this.type,
    required this.location,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.contactName,
    this.contactRole,
    this.phone,
    this.email,
    this.source,
    this.assignedTo,
    this.nextAction,
    this.nextActionNote,
    this.totalProperties,
    this.totalRooms,
    this.interestedPlan,
    this.interestedServices = const [],
    this.currentHms,
    this.websiteStatus,
  });

  bool get isOverdue =>
      nextAction != null && nextAction!.isBefore(DateTime.now());
}
