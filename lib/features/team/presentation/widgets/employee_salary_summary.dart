import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/employee_salary.dart';

class EmployeeSalarySummary extends StatelessWidget {
  final EmployeeSalary salary;

  const EmployeeSalarySummary({super.key, required this.salary});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    Widget row(String label, int amount, {bool primary = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(color: nec.textSecondary, fontSize: 14))),
          Flexible(
              child: Text(salary.money(amount),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: primary ? nec.brand : nec.textPrimary,
                      fontSize: primary ? 18 : 14,
                      fontWeight:
                          primary ? FontWeight.w700 : FontWeight.w500))),
        ]));
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: nec.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          row('Basic salary', salary.basic),
          row('Total additions', salary.totalAdditions),
          row('Gross salary', salary.gross),
          row('Total deductions', salary.totalDeductions),
          Divider(color: nec.separator),
          row('Take-home pay', salary.net, primary: true),
        ]));
  }
}
