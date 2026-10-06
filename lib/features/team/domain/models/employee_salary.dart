import 'package:intl/intl.dart';

/// Amounts are stored in minor currency units to avoid rounding payroll totals.
class SalaryComponent {
  final String name;
  final int amount;

  const SalaryComponent({required this.name, required this.amount});

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  factory SalaryComponent.fromJson(Map<String, dynamic> json) =>
      SalaryComponent(
          name: json['name'] as String, amount: json['amount'] as int);
}

class EmployeeSalary {
  final int basic;
  final List<SalaryComponent> additions;
  final List<SalaryComponent> deductions;
  final String currency;
  final String frequency;
  final int payday;
  final String effectiveDate;
  final String paymentMethod;
  final String accountHolder;
  final String bankName;
  final String accountNumber;
  final String branch;
  final String routingNumber;
  final String walletProvider;
  final String walletNumber;
  final String notes;

  const EmployeeSalary({
    required this.basic,
    this.additions = const [],
    this.deductions = const [],
    this.currency = 'BDT',
    this.frequency = 'Monthly',
    this.payday = 1,
    this.effectiveDate = '',
    this.paymentMethod = 'Bank transfer',
    this.accountHolder = '',
    this.bankName = '',
    this.accountNumber = '',
    this.branch = '',
    this.routingNumber = '',
    this.walletProvider = '',
    this.walletNumber = '',
    this.notes = '',
  });

  int get totalAdditions => additions.fold(0, (sum, item) => sum + item.amount);

  int get totalDeductions =>
      deductions.fold(0, (sum, item) => sum + item.amount);

  int get gross => basic + totalAdditions;

  int get net => gross - totalDeductions;

  String money(int amount) =>
      '$currency ${NumberFormat('#,##0.00').format(amount / 100)}';

  static String formatCurrency(int amount, [String currency = 'BDT']) =>
      '$currency ${NumberFormat('#,##0.00').format(amount / 100)}';

  static int? parseAmount(String value) {
    final text = value.trim();
    if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    return int.parse(parts[0]) * 100 +
        (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  }

  static String inputAmount(int value) => (value / 100).toStringAsFixed(2);

  Map<String, dynamic> toJson() => {
        'basic': basic,
        'additions': additions.map((item) => item.toJson()).toList(),
        'deductions': deductions.map((item) => item.toJson()).toList(),
        'currency': currency,
        'frequency': frequency,
        'payday': payday,
        'effectiveDate': effectiveDate,
        'paymentMethod': paymentMethod,
        'accountHolder': accountHolder,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'branch': branch,
        'routingNumber': routingNumber,
        'walletProvider': walletProvider,
        'walletNumber': walletNumber,
        'notes': notes,
      };

  factory EmployeeSalary.fromJson(Map<String, dynamic> json) => EmployeeSalary(
        basic: json['basic'] as int,
        additions: (json['additions'] as List)
            .map((item) => SalaryComponent.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        deductions: (json['deductions'] as List)
            .map((item) => SalaryComponent.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        currency: json['currency'] as String,
        frequency: json['frequency'] as String,
        payday: json['payday'] as int,
        effectiveDate: json['effectiveDate'] as String,
        paymentMethod: json['paymentMethod'] as String,
        accountHolder: json['accountHolder'] as String,
        bankName: json['bankName'] as String,
        accountNumber: json['accountNumber'] as String,
        branch: json['branch'] as String,
        routingNumber: json['routingNumber'] as String,
        walletProvider: json['walletProvider'] as String,
        walletNumber: json['walletNumber'] as String,
        notes: json['notes'] as String,
      );
}
