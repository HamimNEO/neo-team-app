import 'package:flutter/cupertino.dart';

enum ExpenseCategory {
  office('Office & Rent', CupertinoIcons.building_2_fill, Color(0xFF5856D6)),
  utilities('Utilities & Bills', CupertinoIcons.bolt_fill, Color(0xFFFF9500)),
  software('Software & Tools', CupertinoIcons.cloud_fill, Color(0xFF007AFF)),
  hardware(
      'Hardware & Devices', CupertinoIcons.device_laptop, Color(0xFF34C759)),
  food('Food & Catering', CupertinoIcons.cart_fill, Color(0xFFFF2D55)),
  travel('Travel & Conveyance', CupertinoIcons.car_fill, Color(0xFFAF52DE)),
  marketing(
      'Marketing & Ads', CupertinoIcons.speaker_2_fill, Color(0xFFFF3B30)),
  payroll(
      'Contractors & Bonuses', CupertinoIcons.person_2_fill, Color(0xFF00C7BE)),
  misc('Miscellaneous', CupertinoIcons.ellipsis_circle_fill, Color(0xFF8E8E93));

  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.label, this.icon, this.color);

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.misc;
    return ExpenseCategory.values.firstWhere(
      (c) =>
          c.name.toLowerCase() == value.toLowerCase() ||
          c.label.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseCategory.misc,
    );
  }
}

enum ExpenseStatus {
  paid('Paid', Color(0xFF34C759)),
  pending('Pending', Color(0xFFFF9500)),
  approved('Approved', Color(0xFF007AFF));

  final String label;
  final Color color;

  const ExpenseStatus(this.label, this.color);

  static ExpenseStatus fromString(String? value) {
    if (value == null) return ExpenseStatus.paid;
    return ExpenseStatus.values.firstWhere(
      (s) =>
          s.name.toLowerCase() == value.toLowerCase() ||
          s.label.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseStatus.paid,
    );
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String paymentMethod;
  final ExpenseStatus status;
  final String vendor;
  final String paidBy;
  final String notes;
  final String? receiptName;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.paymentMethod = 'Bank Transfer',
    this.status = ExpenseStatus.paid,
    this.vendor = '',
    this.paidBy = 'Company Account',
    this.notes = '',
    this.receiptName,
  });

  String get formattedAmount {
    final isInt = amount % 1 == 0;
    final numStr =
        isInt ? amount.toInt().toString() : amount.toStringAsFixed(2);
    final parts = numStr.split('.');
    final whole = parts[0];
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedWhole = whole.replaceAllMapped(reg, (Match m) => '${m[1]},');
    if (parts.length > 1) {
      return '৳ $formattedWhole.${parts[1]}';
    }
    return '৳ $formattedWhole';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category.name,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
        'status': status.name,
        'vendor': vendor,
        'paidBy': paidBy,
        'notes': notes,
        'receiptName': receiptName,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String? ??
            'exp_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] as String? ?? 'Expense',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        category: ExpenseCategory.fromString(json['category'] as String?),
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        paymentMethod: json['paymentMethod'] as String? ?? 'Bank Transfer',
        status: ExpenseStatus.fromString(json['status'] as String?),
        vendor: json['vendor'] as String? ?? '',
        paidBy: json['paidBy'] as String? ?? 'Company Account',
        notes: json['notes'] as String? ?? '',
        receiptName: json['receiptName'] as String?,
      );

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? paymentMethod,
    ExpenseStatus? status,
    String? vendor,
    String? paidBy,
    String? notes,
    String? receiptName,
  }) =>
      Expense(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        date: date ?? this.date,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        status: status ?? this.status,
        vendor: vendor ?? this.vendor,
        paidBy: paidBy ?? this.paidBy,
        notes: notes ?? this.notes,
        receiptName: receiptName ?? this.receiptName,
      );
}
