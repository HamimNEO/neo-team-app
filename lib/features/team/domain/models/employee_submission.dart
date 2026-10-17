import 'employee.dart';
import 'employee_salary.dart';

/// Explicit write payload; it is never persisted by the employee cache.
class EmployeeSubmission {
  const EmployeeSubmission(
      {required this.employee,
      required this.roleKey,
      required this.accessScope,
      this.password,
      this.removePhoto = false});

  final Employee employee;
  final String roleKey, accessScope;
  final String? password;
  final bool removePhoto;

  Map<String, dynamic> profilePayload() => {
        'name': employee.name,
        'phone': employee.phone,
        'designation': employee.designation,
        'department_id': employee.departmentId,
        'team': employee.team,
        'reporting_manager_id':
            employee.reportsToId?.replaceFirst('api_emp_', ''),
        'joining_date': employee.joinedDate,
        'employment_status': employee.status.toLowerCase(),
        'employment_type': employee.employmentType,
        if (employee.isProbation) ...{
          'probation_start_date': employee.probationStartDate,
          'probation_end_date': employee.probationEndDate,
        },
        if (employee.hasAgreementPdf) ...{
          'agreement_pdf_name': employee.agreementPdfName,
          if (employee.agreementPdfBase64 != null)
            'agreement_pdf_base64': employee.agreementPdfBase64,
        },
        'address': employee.address,
        'date_of_birth':
            employee.dateOfBirth.isEmpty ? null : employee.dateOfBirth,
        'emergency_contact_name': employee.emergencyContactName,
        'emergency_contact_phone': employee.emergencyContactPhone,
        if (removePhoto) 'remove_photo': true,
      };

  Map<String, dynamic> createPayload() {
    final salary = employee.salary;
    String amount(int value) => EmployeeSalary.inputAmount(value);
    return {
      ...profilePayload(),
      'email': employee.email,
      'password': password,
      'employee_code': employee.employeeCode,
      'role_key': roleKey,
      'access_scope': accessScope,
      'salary_enabled': salary != null,
      if (salary != null) ...{
        'currency': salary.currency,
        'basic_salary': amount(salary.basic),
        'salary_additions': salary.additions
            .map((line) => {'name': line.name, 'amount': amount(line.amount)})
            .toList(),
        'salary_deductions': salary.deductions
            .map((line) => {'name': line.name, 'amount': amount(line.amount)})
            .toList(),
        'pay_frequency': salary.frequency.toLowerCase(),
        'salary_payment_day': salary.payday,
        'effective_from': salary.effectiveDate,
        'payment_method': {
          'Bank transfer': 'bank_transfer',
          'Mobile banking': 'mobile_banking',
          'Cash': 'cash'
        }[salary.paymentMethod],
        'account_holder_name': salary.accountHolder,
        'bank_name': salary.paymentMethod == 'Mobile banking'
            ? salary.walletProvider
            : salary.bankName,
        'account_number': salary.paymentMethod == 'Mobile banking'
            ? salary.walletNumber
            : salary.accountNumber,
        'branch': salary.branch,
        'routing_swift_code': salary.routingNumber,
        'payroll_notes': salary.notes,
        'company_meal_enabled': employee.companyMealEnabled,
        'company_meal_cost': amount(employee.totalMealCost),
        'company_meal_contribution': amount(employee.mealCompanyPayAmount),
        'rotational_reserve_enabled': employee.hasRotationalReserve,
        'rotational_reserve_deduction':
            amount(employee.rotationalReserveAmount),
      },
    };
  }
}
