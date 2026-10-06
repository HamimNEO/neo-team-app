import 'package:flutter/material.dart';
import '../../domain/models/employee_salary.dart';

class SalaryLineDraft {
  final TextEditingController name;
  final TextEditingController amount;

  SalaryLineDraft([SalaryComponent? component])
      : name = TextEditingController(text: component?.name ?? ''),
        amount = TextEditingController(
            text: component == null
                ? ''
                : EmployeeSalary.inputAmount(component.amount));

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class EmployeeSalaryDraft extends ChangeNotifier {
  late final TextEditingController basic;
  late final TextEditingController effectiveDate;
  late final TextEditingController accountHolder;
  late final TextEditingController bankName;
  late final TextEditingController accountNumber;
  late final TextEditingController branch;
  late final TextEditingController routingNumber;
  late final TextEditingController walletProvider;
  late final TextEditingController walletNumber;
  late final TextEditingController notes;
  final List<SalaryLineDraft> additions = [];
  final List<SalaryLineDraft> deductions = [];
  final List<SalaryLineDraft> _removed = [];
  bool enabled;
  String currency;
  String frequency;
  int payday;
  String paymentMethod;
  bool isMealFree;
  int mealCoPayPercent;
  late final TextEditingController totalMealCost;
  bool hasRotationalReserve;
  late final TextEditingController rotationalReserveAmount;

  int get parsedTotalMealCost =>
      EmployeeSalary.parseAmount(totalMealCost.text) ?? 0;

  int get mealEmployeePayAmount =>
      isMealFree ? 0 : ((parsedTotalMealCost * mealCoPayPercent) / 100).round();

  int get mealCompanyCoverageAmount =>
      isMealFree ? parsedTotalMealCost : (parsedTotalMealCost - mealEmployeePayAmount);

  EmployeeSalaryDraft(
    EmployeeSalary? salary, {
    bool enableByDefault = true,
    bool initialIsMealFree = true,
    int initialMealCoPayPercent = 0,
    int initialTotalMealCost = 300000,
    bool initialHasRotationalReserve = false,
    int initialRotationalReserveAmount = 0,
  })  : enabled = salary != null || enableByDefault,
        currency = salary?.currency ?? 'BDT',
        frequency = salary?.frequency ?? 'Monthly',
        payday = salary?.payday ?? 1,
        paymentMethod = salary?.paymentMethod ?? 'Bank transfer',
        isMealFree = initialIsMealFree,
        mealCoPayPercent = initialMealCoPayPercent,
        hasRotationalReserve = initialHasRotationalReserve {
    totalMealCost = TextEditingController(
        text: initialTotalMealCost > 0
            ? EmployeeSalary.inputAmount(initialTotalMealCost)
            : '3000.00');
    rotationalReserveAmount = TextEditingController(
        text: initialRotationalReserveAmount > 0
            ? EmployeeSalary.inputAmount(initialRotationalReserveAmount)
            : '2000.00');
    basic = TextEditingController(
        text: salary == null ? '' : EmployeeSalary.inputAmount(salary.basic));
    effectiveDate = TextEditingController(
        text: salary?.effectiveDate ??
            DateTime.now().toIso8601String().substring(0, 10));
    accountHolder = TextEditingController(text: salary?.accountHolder ?? '');
    bankName = TextEditingController(text: salary?.bankName ?? '');
    accountNumber = TextEditingController(text: salary?.accountNumber ?? '');
    branch = TextEditingController(text: salary?.branch ?? '');
    routingNumber = TextEditingController(text: salary?.routingNumber ?? '');
    walletProvider = TextEditingController(text: salary?.walletProvider ?? '');
    walletNumber = TextEditingController(text: salary?.walletNumber ?? '');
    notes = TextEditingController(text: salary?.notes ?? '');
    basic.addListener(notifyListeners);
    totalMealCost.addListener(notifyListeners);
    rotationalReserveAmount.addListener(notifyListeners);
    for (final line in salary?.additions ?? <SalaryComponent>[]) {
      _append(additions, SalaryLineDraft(line));
    }
    for (final line in salary?.deductions ?? <SalaryComponent>[]) {
      _append(deductions, SalaryLineDraft(line));
    }
  }

  void change(VoidCallback update) {
    update();
    notifyListeners();
  }

  void _append(List<SalaryLineDraft> list, SalaryLineDraft line) {
    list.add(line);
    line.amount.addListener(notifyListeners);
  }

  void addLine(bool deduction) {
    _append(deduction ? deductions : additions, SalaryLineDraft());
    notifyListeners();
  }

  void removeLine(bool deduction, SalaryLineDraft line) {
    (deduction ? deductions : additions).remove(line);
    line.amount.removeListener(notifyListeners);
    _removed.add(line);
    notifyListeners();
  }

  EmployeeSalary buildSalary() => EmployeeSalary(
        basic: EmployeeSalary.parseAmount(basic.text) ?? 0,
        additions: additions
            .map((line) => SalaryComponent(
                name: line.name.text.trim(),
                amount: EmployeeSalary.parseAmount(line.amount.text) ?? 0))
            .toList(),
        deductions: deductions
            .map((line) => SalaryComponent(
                name: line.name.text.trim(),
                amount: EmployeeSalary.parseAmount(line.amount.text) ?? 0))
            .toList(),
        currency: currency,
        frequency: frequency,
        payday: payday,
        effectiveDate: effectiveDate.text,
        paymentMethod: paymentMethod,
        accountHolder: accountHolder.text.trim(),
        bankName: paymentMethod == 'Bank transfer' ? bankName.text.trim() : '',
        accountNumber:
            paymentMethod == 'Bank transfer' ? accountNumber.text.trim() : '',
        branch: paymentMethod == 'Bank transfer' ? branch.text.trim() : '',
        routingNumber:
            paymentMethod == 'Bank transfer' ? routingNumber.text.trim() : '',
        walletProvider:
            paymentMethod == 'Mobile banking' ? walletProvider.text.trim() : '',
        walletNumber:
            paymentMethod == 'Mobile banking' ? walletNumber.text.trim() : '',
        notes: notes.text.trim(),
      );

  @override
  void dispose() {
    for (final controller in [
      basic,
      effectiveDate,
      accountHolder,
      bankName,
      accountNumber,
      branch,
      routingNumber,
      walletProvider,
      walletNumber,
      notes,
      totalMealCost,
      rotationalReserveAmount,
    ]) {
      controller.dispose();
    }
    for (final line in [...additions, ...deductions, ..._removed]) {
      line.dispose();
    }
    super.dispose();
  }
}
