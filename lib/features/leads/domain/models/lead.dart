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
  final String? assignedEmployeeId;
  final String notes;
  final String? attachmentName;
  final bool isWhatsAppSame;
  final String scheduleNote;
  final String scheduleGroup;
  final bool? overdueSnapshot;
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
    this.assignedEmployeeId,
    this.notes = '',
    this.attachmentName,
    this.isWhatsAppSame = false,
    this.scheduleNote = 'New lead',
    this.scheduleGroup = 'TODAY',
    this.overdueSnapshot,
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
      overdueSnapshot ??
      (nextAction != null && nextAction!.isBefore(DateTime.now()));

  Map<String, dynamic> toJson() => {
        'id': id,
        'company': company,
        'type': type,
        'location': location,
        'status': status,
        'priority': priority,
        'contactName': contactName,
        'contactRole': contactRole,
        'phone': phone,
        'email': email,
        'source': source,
        'assignedTo': assignedTo,
        'assignedEmployeeId': assignedEmployeeId,
        'createdAt': createdAt.toIso8601String(),
        'nextAction': nextAction?.toIso8601String(),
        'nextActionNote': nextActionNote,
        'totalProperties': totalProperties,
        'totalRooms': totalRooms,
        'interestedPlan': interestedPlan,
        'interestedServices': interestedServices,
        'currentHms': currentHms,
        'websiteStatus': websiteStatus,
        'notes': notes,
        'attachmentName': attachmentName,
        'isWhatsAppSame': isWhatsAppSame,
        'scheduleNote': scheduleNote,
        'scheduleGroup': scheduleGroup,
        'overdueSnapshot': overdueSnapshot,
      };

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as String,
        company: json['company'] as String,
        type: json['type'] as String,
        location: json['location'] as String,
        status: json['status'] as String,
        priority: json['priority'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        contactName: json['contactName'] as String?,
        contactRole: json['contactRole'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        source: json['source'] as String?,
        assignedTo: json['assignedTo'] as String?,
        assignedEmployeeId: json['assignedEmployeeId'] as String?,
        nextAction: json['nextAction'] == null
            ? null
            : DateTime.parse(json['nextAction'] as String),
        nextActionNote: json['nextActionNote'] as String?,
        totalProperties: json['totalProperties'] as int?,
        totalRooms: json['totalRooms'] as int?,
        interestedPlan: json['interestedPlan'] as String?,
        interestedServices:
            List<String>.from(json['interestedServices'] as List? ?? []),
        currentHms: json['currentHms'] as String?,
        websiteStatus: json['websiteStatus'] as String?,
        notes: json['notes'] as String? ?? '',
        attachmentName: json['attachmentName'] as String?,
        isWhatsAppSame: json['isWhatsAppSame'] as bool? ?? false,
        scheduleNote: json['scheduleNote'] as String? ?? 'New lead',
        scheduleGroup: json['scheduleGroup'] as String? ?? 'TODAY',
        overdueSnapshot: json['overdueSnapshot'] as bool?,
      );
}
