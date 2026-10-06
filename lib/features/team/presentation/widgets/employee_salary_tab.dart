import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/employee.dart';
import 'employee_details_section.dart';
import 'employee_salary_summary.dart';

class EmployeeSalaryTab extends StatelessWidget {
  final Employee employee;

  const EmployeeSalaryTab({super.key, required this.employee});

  Widget _benefitsCard(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final monthlyReserve = employee.rotationalReserveAmount;
    final annualReserve = monthlyReserve * 12;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nec.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: nec.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(CupertinoIcons.shield_lefthalf_fill,
                    color: nec.brand, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benefits & Policy Deductions',
                      style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Company meal coverage and rotational reserve scheme',
                      style: TextStyle(color: nec.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: nec.separator),
          const SizedBox(height: 14),

          // Meal Policy Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: employee.isMealFree
                      ? Colors.teal.withValues(alpha: 0.12)
                      : const Color(0xFFFF9500).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.cart_fill,
                  size: 18,
                  color: employee.isMealFree ? Colors.teal : const Color(0xFFFF9500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Company Meal Policy',
                          style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: employee.isMealFree
                                ? Colors.teal.withValues(alpha: 0.15)
                                : const Color(0xFFFF9500).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            employee.isMealFree
                                ? '100% Free'
                                : '${employee.mealCoPayPercent}% Co-Pay',
                            style: TextStyle(
                              color: employee.isMealFree
                                  ? Colors.teal
                                  : const Color(0xFFFF9500),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.isMealFree
                          ? 'Company covers 100% of lunch & meals (৳${(employee.totalMealCost / 100).toStringAsFixed(0)} / mo). Zero salary deduction.'
                          : 'Total Meal Cost: ৳${(employee.totalMealCost / 100).toStringAsFixed(0)} / mo · Employee pays ${employee.mealCoPayPercent}% (৳${(employee.mealEmployeePayAmount / 100).toStringAsFixed(0)} deducted from salary) · Company sponsors ৳${(employee.mealCompanyPayAmount / 100).toStringAsFixed(0)}.',
                      style: TextStyle(color: nec.textSecondary, fontSize: 12),
                    ),
                    if (!employee.isMealFree) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Monthly Payroll Deduction: ৳${(employee.mealEmployeePayAmount / 100).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFFFF9500),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: nec.separator),
          const SizedBox(height: 14),

          // Rotational Reserve Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: employee.hasRotationalReserve
                      ? const Color(0xFF007AFF).withValues(alpha: 0.12)
                      : nec.textTertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.archivebox_fill,
                  size: 18,
                  color: employee.hasRotationalReserve
                      ? const Color(0xFF007AFF)
                      : nec.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Rotational Reserve Fund',
                          style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: employee.hasRotationalReserve
                                ? nec.brand.withValues(alpha: 0.15)
                                : nec.textTertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            employee.hasRotationalReserve
                                ? 'Active'
                                : 'Not Enrolled',
                            style: TextStyle(
                              color: employee.hasRotationalReserve
                                  ? nec.brand
                                  : nec.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.hasRotationalReserve
                          ? '৳${(monthlyReserve / 100).toStringAsFixed(0)} withheld per month. Accumulated ৳${(annualReserve / 100).toStringAsFixed(0)} withdrawable in December.'
                          : 'Rotational reserve is not enabled for this employee account.',
                      style: TextStyle(color: nec.textSecondary, fontSize: 12),
                    ),
                    if (employee.hasRotationalReserve) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: nec.brand.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.calendar,
                                size: 14, color: nec.brand),
                            const SizedBox(width: 6),
                            Text(
                              'Withdrawal Month: December (Year-End Payout)',
                              style: TextStyle(
                                color: nec.brand,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final salary = employee.salary;
    if (salary == null) {
      return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _benefitsCard(context),
            const SizedBox(height: 16),
            Icon(CupertinoIcons.money_dollar_circle,
                size: 44, color: nec.textTertiary),
            const SizedBox(height: 12),
            Text('Base salary not configured',
                style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
                'Your administrator can add the base salary structure and payment details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: nec.textSecondary, fontSize: 14)),
          ]));
    }
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${salary.frequency} salary · ${salary.currency}',
              style: TextStyle(color: nec.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          EmployeeSalarySummary(salary: salary),
          const SizedBox(height: 16),
          _benefitsCard(context),
          EmployeeDetailsSection(
              title: 'Additions',
              rows: salary.additions.isEmpty
                  ? [('Allowances & earnings', salary.money(0))]
                  : salary.additions
                      .map((item) => (item.name, salary.money(item.amount)))
                      .toList()),
          EmployeeDetailsSection(
              title: 'Deductions',
              rows: salary.deductions.isEmpty
                  ? [('Deductions', salary.money(0))]
                  : salary.deductions
                      .map((item) => (item.name, salary.money(item.amount)))
                      .toList()),
          EmployeeDetailsSection(title: 'Payment information', rows: [
            ('Pay Frequency', salary.frequency),
            ('Effective From', salary.effectiveDate),
            if (salary.frequency == 'Monthly')
              ('Payment Day', 'Day ${salary.payday} of each month'),
            ('Payment Method', salary.paymentMethod),
            if (salary.paymentMethod != 'Cash')
              ('Account Holder', salary.accountHolder),
            if (salary.paymentMethod == 'Bank transfer') ...[
              ('Bank', salary.bankName),
              ('Account Number', salary.accountNumber),
              ('Branch', salary.branch),
              ('Routing / SWIFT', salary.routingNumber),
            ],
            if (salary.paymentMethod == 'Mobile banking') ...[
              ('Provider', salary.walletProvider),
              ('Account Number', salary.walletNumber),
            ],
          ]),
          if (salary.notes.isNotEmpty)
            EmployeeDetailsSection(
                title: 'Payroll notes', rows: [('Notes', salary.notes)]),
          const SizedBox(height: 16),
          Text(
              'Salary details are managed by your administrator. Contact them if any information needs updating.',
              style: TextStyle(
                  color: nec.textTertiary, fontSize: 12, height: 1.5)),
        ]));
  }
}
