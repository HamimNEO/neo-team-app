import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../domain/models/employee_salary.dart';
import 'employee_form_field.dart';
import 'employee_salary_draft.dart';
import 'employee_salary_summary.dart';

class EmployeeSalaryStep extends StatelessWidget {
  final EmployeeSalaryDraft draft;
  final GlobalKey<FormState> formKey;
  final VoidCallback onContinue;

  const EmployeeSalaryStep(
      {super.key,
      required this.draft,
      required this.formKey,
      required this.onContinue});

  String? _amountValidator(String? value) {
    final amount = EmployeeSalary.parseAmount(value ?? '');
    return amount == null
        ? 'Enter a valid amount with up to 2 decimals.'
        : null;
  }

  Widget _choice(BuildContext context, String label, String selected,
      List<String> options, ValueChanged<String> onSelected) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: nec.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                border: Border.all(color: nec.separator),
                borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              menuMaxHeight: 280,
              borderRadius: BorderRadius.circular(14),
              dropdownColor: nec.surface,
              icon: Icon(CupertinoIcons.chevron_down,
                  size: 14, color: nec.textTertiary),
              style: TextStyle(color: nec.textPrimary, fontSize: 15),
              items: options
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onSelected(value);
              },
            )),
          ),
        ]));
  }

  Widget _lines(BuildContext context, bool deduction) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final lines = deduction ? draft.deductions : draft.additions;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(deduction ? 'Salary Deductions' : 'Salary Additions',
                style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600))),
        CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => draft.addLine(deduction),
            child:
                Icon(CupertinoIcons.add_circled, color: nec.brand, size: 24)),
      ]),
      if (lines.isEmpty)
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
                deduction
                    ? 'Add tax, provident fund, advances, or other deductions.'
                    : 'Add allowances, bonuses, overtime, or other earnings.',
                style: TextStyle(color: nec.textTertiary, fontSize: 12))),
      for (final line in lines)
        Container(
            key: ObjectKey(line),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: nec.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: Text(deduction ? 'Deduction' : 'Addition',
                        style:
                            TextStyle(color: nec.textSecondary, fontSize: 12))),
                CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => draft.removeLine(deduction, line),
                    child: const Icon(CupertinoIcons.minus_circle,
                        size: 20, color: CupertinoColors.systemRed))
              ]),
              EmployeeFormField(
                  label: 'Name *',
                  controller: line.name,
                  hint: deduction
                      ? 'e.g. Income tax'
                      : 'e.g. House rent allowance',
                  validator: requiredEmployeeField),
              EmployeeFormField(
                  label: 'Amount (${draft.currency}) *',
                  controller: line.amount,
                  hint: '0.00',
                  validator: _amountValidator,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ]),
            ])),
    ]);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: draft,
      builder: (context, _) {
        final nec = Theme.of(context).extension<NecColors>()!;
        final salary = draft.buildSalary();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
              key: formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Salary Information',
                              style: TextStyle(
                                  color: nec.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600))),
                      CupertinoSwitch(
                          value: draft.enabled,
                          onChanged: (value) =>
                              draft.change(() => draft.enabled = value))
                    ]),
                    Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        child: Text(
                            draft.enabled
                                ? 'Amounts apply to each pay period. Take-home pay is calculated automatically.'
                                : 'Salary can be configured later by an administrator.',
                            style: TextStyle(
                                color: nec.textSecondary, fontSize: 13))),
                    if (draft.enabled) ...[
                      _choice(
                          context,
                          'Currency',
                          draft.currency,
                          ['BDT', 'INR', 'USD', 'EUR', 'GBP'],
                          (value) =>
                              draft.change(() => draft.currency = value)),
                      EmployeeFormField(
                          label: 'Basic Salary (${draft.currency}) *',
                          controller: draft.basic,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                          ],
                          validator: (value) =>
                              _amountValidator(value) ??
                              ((EmployeeSalary.parseAmount(value!) ?? 0) <= 0
                                  ? 'Basic salary must be greater than zero.'
                                  : null)),
                      _lines(context, false),
                      _lines(context, true),
                      EmployeeSalarySummary(salary: salary),
                      if (salary.net < 0)
                        const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                                'Deductions cannot exceed gross salary.',
                                style: TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 13))),
                      const SizedBox(height: 20),
                      _companyBenefitsSection(context),
                      const SizedBox(height: 12),
                      _choice(
                          context,
                          'Pay Frequency',
                          draft.frequency,
                          ['Monthly', 'Fortnightly', 'Weekly'],
                          (value) =>
                              draft.change(() => draft.frequency = value)),
                      if (draft.frequency == 'Monthly') ...[
                        _choice(
                            context,
                            'Salary Payment Day',
                            draft.payday.toString(),
                            List.generate(31, (index) => '${index + 1}'),
                            (value) => draft
                                .change(() => draft.payday = int.parse(value))),
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                                'In shorter months, payment falls on the last day of the month.',
                                style: TextStyle(
                                    color: nec.textTertiary, fontSize: 12))),
                      ],
                      EmployeeFormField(
                          label: 'Effective From *',
                          controller: draft.effectiveDate,
                          readOnly: true,
                          validator: requiredEmployeeField,
                          onTap: () async {
                            final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(
                                        draft.effectiveDate.text) ??
                                    DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100));
                            if (context.mounted && date != null) {
                              draft.effectiveDate.text =
                                  date.toIso8601String().substring(0, 10);
                            }
                          }),
                      _choice(
                          context,
                          'Payment Method',
                          draft.paymentMethod,
                          ['Bank transfer', 'Mobile banking', 'Cash'],
                          (value) =>
                              draft.change(() => draft.paymentMethod = value)),
                      if (draft.paymentMethod != 'Cash')
                        EmployeeFormField(
                            label: 'Account Holder Name *',
                            controller: draft.accountHolder,
                            validator: requiredEmployeeField),
                      if (draft.paymentMethod == 'Bank transfer') ...[
                        EmployeeFormField(
                            label: 'Bank Name *',
                            controller: draft.bankName,
                            validator: requiredEmployeeField),
                        EmployeeFormField(
                            label: 'Account Number *',
                            controller: draft.accountNumber,
                            validator: requiredEmployeeField),
                        EmployeeFormField(
                            label: 'Branch', controller: draft.branch),
                        EmployeeFormField(
                            label: 'Routing / SWIFT Code',
                            controller: draft.routingNumber),
                      ],
                      if (draft.paymentMethod == 'Mobile banking') ...[
                        EmployeeFormField(
                            label: 'Provider *',
                            controller: draft.walletProvider,
                            hint: 'e.g. bKash, Nagad, Rocket',
                            validator: requiredEmployeeField),
                        EmployeeFormField(
                            label: 'Mobile Account Number *',
                            controller: draft.walletNumber,
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                requiredEmployeeField(value) ??
                                employeePhoneValidator(value)),
                      ],
                      EmployeeFormField(
                          label: 'Payroll Notes',
                          controller: draft.notes,
                          maxLines: 3),
                    ],
                    const SizedBox(height: 16),
                    NecButton(
                        label: 'Continue',
                        fullWidth: true,
                        onPressed: onContinue),
                  ])),
        );
      });

  Widget _companyBenefitsSection(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final monthlyReserve =
        EmployeeSalary.parseAmount(draft.rotationalReserveAmount.text) ?? 0;
    final annualReserve = monthlyReserve * 12;

    final totalMeal = draft.parsedTotalMealCost;
    final employeeMealPay = draft.mealEmployeePayAmount;
    final companyMealCover = draft.mealCompanyCoverageAmount;

    return Container(
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: nec.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.shield_lefthalf_fill,
                    color: nec.brand, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benefits & Payroll Deductions',
                      style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Configure company meal system & rotational reserve',
                      style: TextStyle(color: nec.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: nec.separator),
          const SizedBox(height: 14),

          // 1. MEAL SCHEME
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.cart_fill,
                    color: Color(0xFFFF9500), size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Provided Meals',
                      style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      draft.isMealFree
                          ? '100% Free: Company sponsors entire meal cost.'
                          : 'Shared Co-Pay: ${draft.mealCoPayPercent}% is deducted from monthly salary.',
                      style: TextStyle(color: nec.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: draft.isMealFree,
                onChanged: (val) {
                  draft.change(() {
                    draft.isMealFree = val;
                    if (val) {
                      draft.mealCoPayPercent = 0;
                    } else if (draft.mealCoPayPercent == 0) {
                      draft.mealCoPayPercent = 50;
                    }
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Total Monthly Meal Cost Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: nec.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: nec.separator),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Monthly Meal Cost',
                      style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: draft.isMealFree
                            ? Colors.teal.withValues(alpha: 0.15)
                            : nec.brand.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        draft.isMealFree
                            ? '100% Sponsored'
                            : '${draft.mealCoPayPercent}% Co-Pay',
                        style: TextStyle(
                          color: draft.isMealFree ? Colors.teal : nec.brand,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: draft.totalMealCost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'e.g. 3000.00',
                    prefixText: '৳ ',
                    prefixStyle: TextStyle(
                      color: nec.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: nec.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: nec.separator),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: nec.separator),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: nec.brand, width: 1.5),
                    ),
                  ),
                  onChanged: (_) => draft.change(() {}),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [2000, 3000, 4000, 5000].map((amt) {
                    return ActionChip(
                      label: Text('৳$amt'),
                      labelStyle:
                          TextStyle(color: nec.textSecondary, fontSize: 11),
                      backgroundColor: nec.surface,
                      side: BorderSide(color: nec.separator),
                      onPressed: () {
                        draft.change(() {
                          draft.totalMealCost.text =
                              EmployeeSalary.inputAmount(amt * 100);
                        });
                      },
                    );
                  }).toList(),
                ),

                if (draft.isMealFree) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.checkmark_seal_fill,
                            color: Colors.teal, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Company covers full ৳${EmployeeSalary.inputAmount(totalMeal)} / month. ৳0.00 is cut from employee salary.',
                            style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text(
                    'Employee Co-Pay Percentage',
                    style: TextStyle(
                      color: nec.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [30, 40, 50, 60, 70, 80, 100].map((percent) {
                      final isSelected = draft.mealCoPayPercent == percent;
                      return ChoiceChip(
                        label: Text('$percent%'),
                        selected: isSelected,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : nec.textPrimary,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        selectedColor: nec.brand,
                        backgroundColor: nec.surface,
                        side: BorderSide(
                          color: isSelected ? nec.brand : nec.separator,
                        ),
                        onSelected: (_) {
                          draft.change(() => draft.mealCoPayPercent = percent);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: nec.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: nec.brand.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cuts from Salary (${draft.mealCoPayPercent}%):',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: nec.textPrimary,
                              ),
                            ),
                            Text(
                              '৳${EmployeeSalary.inputAmount(employeeMealPay)} / mo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: nec.brand,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Company Covers (${100 - draft.mealCoPayPercent}%):',
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textSecondary,
                              ),
                            ),
                            Text(
                              '৳${EmployeeSalary.inputAmount(companyMealCover)} / mo',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: nec.separator),
          const SizedBox(height: 14),

          // 2. ROTATIONAL RESERVE FUND
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.archivebox_fill,
                    color: Color(0xFF007AFF), size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rotational Reserve Fund',
                      style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      draft.hasRotationalReserve
                          ? 'Deducted monthly; withdrawable in last month (Dec).'
                          : 'Disabled for this employee.',
                      style: TextStyle(color: nec.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: draft.hasRotationalReserve,
                onChanged: (val) {
                  draft.change(() => draft.hasRotationalReserve = val);
                },
              ),
            ],
          ),

          if (draft.hasRotationalReserve) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: nec.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nec.separator),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Reserve Deduction (BDT)',
                    style: TextStyle(
                      color: nec.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: draft.rotationalReserveAmount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'e.g. 2000.00',
                      prefixText: '৳ ',
                      prefixStyle: TextStyle(
                        color: nec.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: nec.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: nec.separator),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: nec.separator),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: nec.brand, width: 1.5),
                      ),
                    ),
                    onChanged: (_) => draft.change(() {}),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [1000, 2000, 3000, 5000].map((amt) {
                      return ActionChip(
                        label: Text('৳$amt'),
                        labelStyle:
                            TextStyle(color: nec.textSecondary, fontSize: 11),
                        backgroundColor: nec.surface,
                        side: BorderSide(color: nec.separator),
                        onPressed: () {
                          draft.change(() {
                            draft.rotationalReserveAmount.text =
                                EmployeeSalary.inputAmount(amt * 100);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: nec.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.calendar_badge_plus,
                            color: nec.brand, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Year-End Payout (December): ${EmployeeSalary.formatCurrency(annualReserve, draft.currency)} accumulated',
                            style: TextStyle(
                              color: nec.brand,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
