import 'lead_status.dart';

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
  final DateTime? updatedAt;
  final DateTime? nextAction;
  final double? latitude;
  final double? longitude;

  const Lead({
    required this.id,
    required this.company,
    required this.type,
    required this.location,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
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
    this.scheduleNote = '',
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
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get coordinatesFormatted {
    if (!hasCoordinates) return '';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

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
        'updatedAt': updatedAt?.toIso8601String(),
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
        'latitude': latitude,
        'longitude': longitude,
      };

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as String,
        company: json['company'] as String,
        type: json['type'] as String,
        location: json['location'] as String,
        status: LeadStatus.label(json['status'] as String),
        priority: json['priority'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
        contactName: json['contactName'] as String?,
        contactRole: json['contactRole'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        source: json['source'] as String?,
        assignedTo: json['assignedTo'] as String?,
        assignedEmployeeId: employeeId(json['assignedEmployeeId']),
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
        scheduleNote: json['scheduleNote'] as String? ?? '',
        scheduleGroup: json['scheduleGroup'] as String? ?? 'TODAY',
        overdueSnapshot: json['overdueSnapshot'] as bool?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toApiPayload() {
    final apiStatus = LeadStatus.api(status);

    String apiPriority = 'medium';
    switch (priority.toLowerCase()) {
      case 'low':
        apiPriority = 'low';
        break;
      case 'high':
      case 'urgent':
        apiPriority = 'high';
        break;
      default:
        apiPriority = 'medium';
    }

    return {
      'business_name': company,
      if (type.isNotEmpty) 'business_type': type,
      if (location.isNotEmpty) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'status': apiStatus,
      'priority': apiPriority,
      if (contactName != null && contactName!.isNotEmpty)
        'contact_name': contactName,
      if (contactRole != null && contactRole!.isNotEmpty)
        'contact_role': contactRole,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (isWhatsAppSame && phone != null) 'whatsapp': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (source != null && source!.isNotEmpty) 'source': source,
      if (assignedEmployeeId != null && assignedEmployeeId!.isNotEmpty)
        'current_owner_id':
            int.tryParse(assignedEmployeeId!.replaceFirst('api_emp_', '')) ??
                assignedEmployeeId!.replaceFirst('api_emp_', ''),
      if (notes.isNotEmpty) 'notes': notes,
      if (totalProperties != null) 'total_properties': totalProperties,
      if (totalRooms != null) 'total_rooms': totalRooms,
      if (interestedPlan != null && interestedPlan!.isNotEmpty)
        'interested_plan': interestedPlan,
      if (interestedServices.isNotEmpty)
        'interested_services': interestedServices,
      if (currentHms != null && currentHms!.isNotEmpty)
        'current_hms': currentHms,
      if (websiteStatus != null && websiteStatus!.isNotEmpty)
        'website_status': websiteStatus,
      if (nextAction != null) 'next_action_at': nextAction!.toIso8601String(),
      if (nextActionNote != null && nextActionNote!.isNotEmpty)
        'next_action_type': nextActionNote,
    };
  }

  static String? employeeId(Object? raw) {
    if (raw == null || raw.toString().isEmpty) return null;
    final value = raw.toString();
    return value.startsWith('api_emp_') ? value : 'api_emp_$value';
  }

  factory Lead.fromApi(Map<String, dynamic> json) {
    Map part(String key) => json[key] is Map ? json[key] as Map : {};
    final business = part('business'), contact = part('contact');
    final qualification = part('qualification'), lifecycle = part('lifecycle');
    final owner = part('owner'), ownership = part('ownership');
    String? text(Object? value) => value?.toString();
    double? number(Object? value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    final status =
        LeadStatus.label(text(json['status'] ?? lifecycle['status']) ?? 'new');
    final priorityRaw =
        (text(json['priority'] ?? lifecycle['priority']) ?? 'medium')
            .toLowerCase();
    final priority = {
          'low': 'Low',
          'medium': 'Normal',
          'normal': 'Normal',
          'high': 'High',
          'urgent': 'Urgent'
        }[priorityRaw] ??
        priorityRaw;
    final services =
        json['interested_services'] ?? qualification['interested_services'];
    final parsedServices = services is List
        ? services.map((e) => e.toString()).toList()
        : services is String && services.isNotEmpty
            ? services.split(',').map((e) => e.trim()).toList()
            : <String>[];
    final nextAction = DateTime.tryParse(text(json['next_action_at']) ?? '');
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final scheduledDay = nextAction == null
        ? null
        : DateTime(nextAction.year, nextAction.month, nextAction.day);
    final group = scheduledDay == null
        ? 'UNSCHEDULED'
        : scheduledDay.isBefore(day)
            ? 'OVERDUE'
            : scheduledDay == day
                ? 'TODAY'
                : scheduledDay == DateTime(now.year, now.month, now.day + 1)
                    ? 'TOMORROW'
                    : 'UPCOMING';
    return Lead(
      id: json['id'].toString(),
      company: text(json['company'] ??
              json['business_name'] ??
              json['name'] ??
              business['name']) ??
          'Unnamed Business',
      type: text(json['business_type'] ?? business['type']) ?? '',
      location: text(json['location'] ?? business['location']) ?? '',
      status: status,
      priority: priority,
      createdAt: DateTime.tryParse(
              text(json['created_at'] ?? lifecycle['created_at']) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
          text(json['updated_at'] ?? lifecycle['updated_at']) ?? ''),
      contactName: text(
          json['contact_person'] ?? json['contact_name'] ?? contact['name']),
      contactRole: text(json['contact_role'] ?? contact['role']),
      phone: text(json['phone'] ?? contact['phone']),
      email: text(json['email'] ?? contact['email']),
      source: text(json['source'] ?? lifecycle['source']),
      assignedEmployeeId: employeeId(
          json['current_owner_id'] ?? owner['id'] ?? ownership['employee_id']),
      assignedTo: text(json['owner_name'] ??
          json['assignee_name'] ??
          owner['name'] ??
          ownership['name']),
      notes: text(json['notes'] ?? qualification['notes']) ?? '',
      nextAction: nextAction,
      nextActionNote: text(json['next_action_type']),
      totalProperties: int.tryParse(
          text(json['total_properties'] ?? business['total_properties']) ?? ''),
      totalRooms: int.tryParse(
          text(json['total_rooms'] ?? business['total_rooms']) ?? ''),
      interestedPlan:
          text(json['interested_plan'] ?? qualification['interested_plan']),
      interestedServices: parsedServices,
      currentHms: text(json['current_hms'] ?? business['current_hms']),
      websiteStatus:
          text(json['website_status'] ?? qualification['website_status']),
      scheduleNote: text(json['next_action_type']) ?? '',
      scheduleGroup: group,
      latitude: number(json['latitude'] ?? json['lat']),
      longitude: number(json['longitude'] ?? json['lng']),
    );
  }
}
