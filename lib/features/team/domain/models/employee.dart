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

  int get mealEmployeePayAmount =>
      isMealFree ? 0 : ((totalMealCost * mealCoPayPercent) / 100).round();

  int get mealCompanyPayAmount =>
      isMealFree ? totalMealCost : (totalMealCost - mealEmployeePayAmount);

  String get displayCode => employeeCode.isNotEmpty
      ? employeeCode
      : 'NEC-${id.replaceAll('emp_', '').toUpperCase()}';

  static String initialsFor(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.first.isEmpty) return 'HL';
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
  });

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
        directReports: (json['directReports'] as List?)
            ?.map((item) =>
                Employee.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}
