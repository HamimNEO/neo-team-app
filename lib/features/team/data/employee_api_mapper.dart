import 'dart:convert';
import '../../../core/network/api_media_url.dart';
import '../domain/models/employee.dart';
import '../domain/models/employee_salary.dart';

int apiMoney(dynamic value) {
  if (value == null) return 0;
  if (value is num) return (value * 100).round();
  final result = EmployeeSalary.parseAmount(value.toString());
  if (result == null) {
    throw const FormatException(
        'The server returned an invalid salary amount.');
  }
  return result;
}

List<SalaryComponent> apiComponents(dynamic value) {
  if (value == null) return [];
  if (value is String) value = jsonDecode(value);
  if (value is! List) {
    throw const FormatException(
        'The server returned invalid salary components.');
  }
  return value
      .map((line) => SalaryComponent(
          name: line['name'] as String, amount: apiMoney(line['amount'])))
      .toList();
}

Employee employeeFromApi(Map<String, dynamic> record, String baseUrl) {
  String text(dynamic value) => value is String ? value : '';
  String? nullable(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'undefined') {
      return null;
    }
    return text;
  }

  final id = record['id'];
  final name = text(record['name']);
  if (id == null || name.isEmpty) {
    throw const FormatException('The server returned an invalid employee.');
  }
  final department = record['department'];
  final role = record['role'];
  final emergency = record['emergency_contact'];
  final nestedSalary = record['salary'];
  final salary =
      nestedSalary is Map ? Map<String, dynamic>.from(nestedSalary) : record;
  final salaryEnabled =
      record['salary_enabled'] == true || (nestedSalary is Map);
  final frequency = text(salary['pay_frequency'] ?? record['pay_frequency']);
  final method = text(salary['payment_method'] ?? record['payment_method']);
  final mealCost = apiMoney(record['company_meal_cost']);
  final contribution = apiMoney(record['company_meal_contribution']);
  final paydayRaw =
      salary['salary_payment_day'] ?? record['salary_payment_day'];
  return Employee(
    id: 'api_emp_$id',
    activity: (record['activity'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    accessModules: (record['access_modules'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    name: name,
    designation: text(record['designation']),
    department: department is Map
        ? text(department['name'])
        : text(record['department_name']),
    departmentId: department is Map
        ? nullable(department['id'])
        : nullable(record['department_id']),
    team: text(record['team']),
    systemRole: role is Map ? text(role['name']) : '',
    roleKey: role is Map ? nullable(role['key']) : null,
    accessScope: nullable(record['access_scope']),
    status: (record['employment_status'] != null
        ? (record['employment_status'] == 'suspended'
            ? 'Suspended'
            : (record['employment_status'] == 'active' ? 'Active' : 'Inactive'))
        : (record['is_active'] == true ? 'Active' : 'Inactive')),
    email: text(record['email']),
    phone: text(record['phone']),
    photoUrl: apiMediaUrl(
        nullable(record['photo_url']) ?? nullable(record['photo']), baseUrl),
    avatarInitials: text(record['initials']).isEmpty
        ? Employee.initialsFor(name)
        : text(record['initials']),
    employeeCode: text(nullable(record['employee_code']) ??
        nullable(record['employee_id']) ??
        record['code']),
    joinedDate: (nullable(record['joining_date']) ??
            nullable(record['joined_at']) ??
            '')
        .split('T')
        .first,
    reportsTo:
        nullable(record['reporting_manager_name'] ?? record['reports_to']),
    reportsToId: record['reporting_manager_id'] == null
        ? null
        : 'api_emp_${record['reporting_manager_id']}',
    address: text(record['address']),
    dateOfBirth: (nullable(record['date_of_birth']) ?? '').split('T').first,
    emergencyContactName: emergency is Map
        ? text(emergency['name'])
        : text(record['emergency_contact_name']),
    emergencyContactPhone: emergency is Map
        ? text(emergency['phone'])
        : text(record['emergency_contact_phone']),
    benefitsKnown: record.containsKey('company_meal_enabled'),
    companyMealEnabled: record['company_meal_enabled'] == true,
    isMealFree: mealCost > 0 && contribution >= mealCost,
    totalMealCost: mealCost,
    mealCoPayPercent: mealCost <= 0
        ? 0
        : ((mealCost - contribution) * 100 / mealCost).round().clamp(0, 100),
    hasRotationalReserve: record['rotational_reserve_enabled'] == true,
    rotationalReserveAmount: apiMoney(record['rotational_reserve_deduction']),
    employmentType: nullable(record['employment_type'])?.toLowerCase() == 'probation'
        ? 'probation'
        : 'permanent',
    probationStartDate: (nullable(record['probation_start_date']) ?? '').split('T').first.isNotEmpty
        ? (nullable(record['probation_start_date']) ?? '').split('T').first
        : null,
    probationEndDate: (nullable(record['probation_end_date']) ?? '').split('T').first.isNotEmpty
        ? (nullable(record['probation_end_date']) ?? '').split('T').first
        : null,
    agreementPdfName: nullable(record['agreement_pdf_name'] ??
        record['agreement_document_name'] ??
        record['agreement_name']),
    agreementPdfUrl: apiMediaUrl(
        nullable(record['agreement_pdf_url'] ??
            record['agreement_document_url'] ??
            record['agreement_url']),
        baseUrl),
    agreementPdfBase64: nullable(record['agreement_pdf_base64']),
    agreementPdfSizeBytes: record['agreement_pdf_size_bytes'] is int
        ? record['agreement_pdf_size_bytes'] as int
        : null,
    salary: !salaryEnabled
        ? null
        : EmployeeSalary(
            basic: apiMoney(salary['basic_salary']),
            additions: apiComponents(
                salary['additions'] ?? record['salary_additions']),
            deductions: apiComponents(
                salary['deductions'] ?? record['salary_deductions']),
            currency: text(salary['currency']),
            frequency: {
                  'monthly': 'Monthly',
                  'fortnightly': 'Fortnightly',
                  'weekly': 'Weekly'
                }[frequency] ??
                frequency,
            payday:
                paydayRaw is int ? paydayRaw : int.tryParse('$paydayRaw') ?? 0,
            effectiveDate:
                text(salary['effective_from'] ?? record['effective_from']),
            paymentMethod: {
                  'bank_transfer': 'Bank transfer',
                  'mobile_banking': 'Mobile banking',
                  'cash': 'Cash'
                }[method] ??
                method,
            accountHolder: text(
                salary['account_holder_name'] ?? record['account_holder_name']),
            bankName: text(salary['bank_name'] ?? record['bank_name']),
            accountNumber:
                text(salary['account_number'] ?? record['account_number']),
            branch: text(salary['branch'] ?? record['branch']),
            routingNumber: text(
                salary['routing_swift_code'] ?? record['routing_swift_code']),
            walletProvider: method == 'mobile_banking'
                ? text(salary['bank_name'] ?? record['bank_name'])
                : '',
            walletNumber: method == 'mobile_banking'
                ? text(salary['account_number'] ?? record['account_number'])
                : '',
            notes: text(salary['payroll_notes'] ?? record['payroll_notes']),
          ),
  );
}
