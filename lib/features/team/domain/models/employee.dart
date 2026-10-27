import 'employee_salary.dart';

class Employee {
  final String id;
  final String name;
  final String designation;
  final String department;
  final String team;
  final String systemRole;
  final String status;
  final String email;
  final String phone;
  final String avatarInitials;
  final String? reportsTo;
  final String? reportsToId;
  final String? reportsToTitle;
  final String? reportsToAvatar;
  final String joinedDate;
  final int activeLeadsCount;
  final int activeTasksCount;
  final List<Employee>? directReports;
  final String employeeCode;
  final String? photoBase64;
  final String? avatarAsset;
  final String? photoUrl, departmentId, roleKey, accessScope;
  final bool benefitsKnown, companyMealEnabled;
  final List<Map<String, dynamic>> activity, accessModules;

  String? get backendId => id.startsWith('api_emp_') ? id.substring(8) : null;
  final String address;
  final String dateOfBirth;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final EmployeeSalary? salary;
  final bool isMealFree;
  final int mealCoPayPercent;
  final int totalMealCost;
  final bool hasRotationalReserve;
  final int rotationalReserveAmount;
  final Map<String, dynamic> probationMetrics;
  final String employmentType;
  final String? probationStartDate;
  final String? probationEndDate;
  final String? agreementPdfName;
  final String? agreementPdfUrl;
  final String? agreementPdfBase64;
  final int? agreementPdfSizeBytes;

  bool get isProbation => employmentType.toLowerCase() == 'probation';

  bool get isPermanent => !isProbation;

  double get probationProgress {
    final value = num.tryParse(
        '${probationMetrics['probation_progress_percent'] ?? probationMetrics['progress_percent']}');
    if (value != null) return (value / 100).clamp(0.0, 1.0);
    if (!isProbation ||
        probationStartDate == null ||
        probationEndDate == null) {
      return 0.0;
    }
    final start = DateTime.tryParse(probationStartDate!);
    final end = DateTime.tryParse(probationEndDate!);
    if (start == null || end == null || end.isBefore(start)) return 0.0;
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 1.0;
    final elapsed = now.difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  int get probationRemainingDays {
    final value = int.tryParse(
        '${probationMetrics['probation_days_remaining'] ?? probationMetrics['days_remaining']}');
    if (value != null) return value < 0 ? 0 : value;
    if (probationEndDate == null) return 0;
    final end = DateTime.tryParse(probationEndDate!);
    if (end == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(end.year, end.month, end.day);
    final diff = target.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get probationTotalDays {
    final value = int.tryParse(
        '${probationMetrics['probation_days_total'] ?? probationMetrics['days_total']}');
    if (value != null) return value < 0 ? 0 : value;
    if (probationStartDate == null || probationEndDate == null) return 0;
    final start = DateTime.tryParse(probationStartDate!);
    final end = DateTime.tryParse(probationEndDate!);
    if (start == null || end == null || end.isBefore(start)) return 0;
    return end.difference(start).inDays;
  }

  int get probationElapsedDays {
    final value = int.tryParse(
        '${probationMetrics['probation_days_completed'] ?? probationMetrics['days_completed']}');
    if (value != null) return value < 0 ? 0 : value;
    if (probationStartDate == null) return 0;
    final start = DateTime.tryParse(probationStartDate!);
    if (start == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final elapsed = today.difference(startDay).inDays;
    if (elapsed < 0) return 0;
    if (probationTotalDays > 0 && elapsed > probationTotalDays) {
      return probationTotalDays;
    }
    return elapsed;
  }

  bool get isProbationCompleted {
    if (!isProbation || probationEndDate == null) return false;
    final end = DateTime.tryParse(probationEndDate!);
    if (end == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(end.year, end.month, end.day);
    return today.isAfter(target) || today.isAtSameMomentAs(target);
  }

  bool get hasAgreementPdf =>
      (agreementPdfName != null && agreementPdfName!.isNotEmpty) ||
      (agreementPdfUrl != null && agreementPdfUrl!.isNotEmpty) ||
      (agreementPdfBase64 != null && agreementPdfBase64!.isNotEmpty);

  int get mealEmployeePayAmount =>
      isMealFree ? 0 : ((totalMealCost * mealCoPayPercent) / 100).round();

  int get mealCompanyPayAmount =>
      isMealFree ? totalMealCost : (totalMealCost - mealEmployeePayAmount);

  String get displayCode => employeeCode.isNotEmpty ? employeeCode : '—';

  static String initialsFor(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.first.isEmpty) return '?';
    return (words.length == 1
            ? words.first
                .substring(0, words.first.length > 2 ? 2 : words.first.length)
            : '${words.first[0]}${words.last[0]}')
        .toUpperCase();
  }

  String get role => systemRole;

  bool get isAdministrator =>
      systemRole == 'Admin' || systemRole == 'Administrator';

  const Employee({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.team,
    required this.systemRole,
    required this.status,
    required this.email,
    required this.phone,
    required this.avatarInitials,
    this.reportsTo,
    this.reportsToId,
    this.reportsToTitle,
    this.reportsToAvatar,
    required this.joinedDate,
    this.activeLeadsCount = 0,
    this.activeTasksCount = 0,
    this.directReports,
    this.employeeCode = '',
    this.photoBase64,
    this.avatarAsset,
    this.photoUrl,
    this.departmentId,
    this.roleKey,
    this.accessScope,
    this.benefitsKnown = false,
    this.companyMealEnabled = false,
    this.activity = const [],
    this.accessModules = const [],
    this.address = '',
    this.dateOfBirth = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.salary,
    this.isMealFree = true,
    this.mealCoPayPercent = 0,
    this.totalMealCost = 300000,
    this.hasRotationalReserve = false,
    this.rotationalReserveAmount = 0,
    this.probationMetrics = const {},
    this.employmentType = 'permanent',
    this.probationStartDate,
    this.probationEndDate,
    this.agreementPdfName,
    this.agreementPdfUrl,
    this.agreementPdfBase64,
    this.agreementPdfSizeBytes,
  });

  Employee copyWith({
    String? id,
    String? name,
    String? designation,
    String? department,
    String? team,
    String? systemRole,
    String? status,
    String? email,
    String? phone,
    String? avatarInitials,
    String? reportsTo,
    String? reportsToId,
    String? reportsToTitle,
    String? reportsToAvatar,
    String? joinedDate,
    int? activeLeadsCount,
    int? activeTasksCount,
    List<Employee>? directReports,
    String? employeeCode,
    String? photoBase64,
    String? avatarAsset,
    String? photoUrl,
    String? departmentId,
    String? roleKey,
    String? accessScope,
    bool? benefitsKnown,
    bool? companyMealEnabled,
    List<Map<String, dynamic>>? activity,
    List<Map<String, dynamic>>? accessModules,
    String? address,
    String? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactPhone,
    EmployeeSalary? salary,
    bool? isMealFree,
    int? mealCoPayPercent,
    int? totalMealCost,
    bool? hasRotationalReserve,
    int? rotationalReserveAmount,
    String? employmentType,
    String? probationStartDate,
    String? probationEndDate,
    String? agreementPdfName,
    String? agreementPdfUrl,
    String? agreementPdfBase64,
    int? agreementPdfSizeBytes,
  }) =>
      Employee(
        id: id ?? this.id,
        name: name ?? this.name,
        designation: designation ?? this.designation,
        department: department ?? this.department,
        team: team ?? this.team,
        systemRole: systemRole ?? this.systemRole,
        status: status ?? this.status,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarInitials: avatarInitials ?? this.avatarInitials,
        reportsTo: reportsTo ?? this.reportsTo,
        reportsToId: reportsToId ?? this.reportsToId,
        reportsToTitle: reportsToTitle ?? this.reportsToTitle,
        reportsToAvatar: reportsToAvatar ?? this.reportsToAvatar,
        joinedDate: joinedDate ?? this.joinedDate,
        activeLeadsCount: activeLeadsCount ?? this.activeLeadsCount,
        activeTasksCount: activeTasksCount ?? this.activeTasksCount,
        directReports: directReports ?? this.directReports,
        employeeCode: employeeCode ?? this.employeeCode,
        photoBase64: photoBase64 ?? this.photoBase64,
        avatarAsset: avatarAsset ?? this.avatarAsset,
        photoUrl: photoUrl ?? this.photoUrl,
        departmentId: departmentId ?? this.departmentId,
        roleKey: roleKey ?? this.roleKey,
        accessScope: accessScope ?? this.accessScope,
        benefitsKnown: benefitsKnown ?? this.benefitsKnown,
        companyMealEnabled: companyMealEnabled ?? this.companyMealEnabled,
        activity: activity ?? this.activity,
        accessModules: accessModules ?? this.accessModules,
        address: address ?? this.address,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        emergencyContactName: emergencyContactName ?? this.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? this.emergencyContactPhone,
        salary: salary ?? this.salary,
        isMealFree: isMealFree ?? this.isMealFree,
        mealCoPayPercent: mealCoPayPercent ?? this.mealCoPayPercent,
        totalMealCost: totalMealCost ?? this.totalMealCost,
        hasRotationalReserve: hasRotationalReserve ?? this.hasRotationalReserve,
        rotationalReserveAmount:
            rotationalReserveAmount ?? this.rotationalReserveAmount,
        probationMetrics: probationMetrics,
        employmentType: employmentType ?? this.employmentType,
        probationStartDate: probationStartDate ?? this.probationStartDate,
        probationEndDate: probationEndDate ?? this.probationEndDate,
        agreementPdfName: agreementPdfName ?? this.agreementPdfName,
        agreementPdfUrl: agreementPdfUrl ?? this.agreementPdfUrl,
        agreementPdfBase64: agreementPdfBase64 ?? this.agreementPdfBase64,
        agreementPdfSizeBytes:
            agreementPdfSizeBytes ?? this.agreementPdfSizeBytes,
      );

  Employee editPersonalDetails(
          {required String name,
          required String phone,
          required String address,
          required String dateOfBirth,
          required String emergencyContactName,
          required String emergencyContactPhone,
          required String? photoBase64}) =>
      Employee.fromJson({
        ...toJson(),
        'name': name,
        'phone': phone,
        'address': address,
        'dateOfBirth': dateOfBirth,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'photoBase64': photoBase64,
        'avatarAsset': avatarAsset,
        'avatarInitials': initialsFor(name),
      });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'designation': designation,
        'department': department,
        'team': team,
        'systemRole': systemRole,
        'status': status,
        'email': email,
        'phone': phone,
        'avatarInitials': avatarInitials,
        'joinedDate': joinedDate,
        'employeeCode': employeeCode,
        'photoBase64': photoBase64,
        'avatarAsset': avatarAsset,
        'photoUrl': photoUrl,
        'departmentId': departmentId,
        'roleKey': roleKey,
        'accessScope': accessScope,
        'benefitsKnown': benefitsKnown,
        'companyMealEnabled': companyMealEnabled,
        'activity': activity,
        'accessModules': accessModules,
        'reportsTo': reportsTo,
        'reportsToId': reportsToId,
        'reportsToTitle': reportsToTitle,
        'reportsToAvatar': reportsToAvatar,
        'activeLeadsCount': activeLeadsCount,
        'activeTasksCount': activeTasksCount,
        'address': address,
        'dateOfBirth': dateOfBirth,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'salary': salary?.toJson(),
        'isMealFree': isMealFree,
        'mealCoPayPercent': mealCoPayPercent,
        'totalMealCost': totalMealCost,
        'hasRotationalReserve': hasRotationalReserve,
        'rotationalReserveAmount': rotationalReserveAmount,
        'probationMetrics': probationMetrics,
        'employmentType': employmentType,
        'probationStartDate': probationStartDate,
        'probationEndDate': probationEndDate,
        'agreementPdfName': agreementPdfName,
        'agreementPdfUrl': agreementPdfUrl,
        'agreementPdfBase64': agreementPdfBase64,
        'agreementPdfSizeBytes': agreementPdfSizeBytes,
        'directReports':
            directReports?.map((employee) => employee.toJson()).toList(),
      };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String,
        name: json['name'] as String,
        designation: json['designation'] as String,
        department: json['department'] as String,
        team: json['team'] as String,
        systemRole: json['systemRole'] as String,
        status: json['status'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        avatarInitials: json['avatarInitials'] as String,
        joinedDate: json['joinedDate'] as String,
        employeeCode: json['employeeCode'] as String? ?? '',
        photoBase64: json['photoBase64'] as String?,
        avatarAsset: json['avatarAsset'] as String?,
        photoUrl: json['photoUrl'] as String?,
        departmentId: json['departmentId'] as String?,
        roleKey: json['roleKey'] as String?,
        accessScope: json['accessScope'] as String?,
        benefitsKnown: json['benefitsKnown'] == true,
        companyMealEnabled: json['companyMealEnabled'] == true,
        activity: (json['activity'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        accessModules: (json['accessModules'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        reportsTo: json['reportsTo'] as String?,
        reportsToId: json['reportsToId'] as String?,
        reportsToTitle: json['reportsToTitle'] as String?,
        reportsToAvatar: json['reportsToAvatar'] as String?,
        activeLeadsCount: json['activeLeadsCount'] as int? ?? 0,
        activeTasksCount: json['activeTasksCount'] as int? ?? 0,
        address: json['address'] as String? ?? '',
        dateOfBirth: json['dateOfBirth'] as String? ?? '',
        emergencyContactName: json['emergencyContactName'] as String? ?? '',
        emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
        salary: json['salary'] == null
            ? null
            : EmployeeSalary.fromJson(
                Map<String, dynamic>.from(json['salary'] as Map)),
        isMealFree: json['isMealFree'] as bool? ?? true,
        mealCoPayPercent: json['mealCoPayPercent'] as int? ?? 0,
        totalMealCost: json['totalMealCost'] as int? ?? 300000,
        hasRotationalReserve: json['hasRotationalReserve'] as bool? ?? false,
        rotationalReserveAmount: json['rotationalReserveAmount'] as int? ?? 0,
        probationMetrics:
            Map<String, dynamic>.from(json['probationMetrics'] as Map? ?? {}),
        employmentType: json['employmentType'] as String? ??
            json['employment_type'] as String? ??
            'permanent',
        probationStartDate: json['probationStartDate'] as String? ??
            json['probation_start_date'] as String?,
        probationEndDate: json['probationEndDate'] as String? ??
            json['probation_end_date'] as String?,
        agreementPdfName: json['agreementPdfName'] as String? ??
            json['agreement_pdf_name'] as String?,
        agreementPdfUrl: json['agreementPdfUrl'] as String? ??
            json['agreement_pdf_url'] as String?,
        agreementPdfBase64: json['agreementPdfBase64'] as String? ??
            json['agreement_pdf_base64'] as String?,
        agreementPdfSizeBytes: json['agreementPdfSizeBytes'] as int? ??
            json['agreement_pdf_size_bytes'] as int?,
        directReports: (json['directReports'] as List?)
            ?.map((item) =>
                Employee.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}
