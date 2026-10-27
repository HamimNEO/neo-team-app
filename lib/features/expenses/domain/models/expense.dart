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

  String get shortLabel {
    switch (this) {
      case ExpenseCategory.office:
        return 'Office';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.software:
        return 'Software';
      case ExpenseCategory.hardware:
        return 'Hardware';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.payroll:
        return 'Payroll';
      case ExpenseCategory.misc:
        return 'Misc';
    }
  }

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
    if (value == null) return ExpenseStatus.pending;
    return ExpenseStatus.values.firstWhere(
      (s) =>
          s.name.toLowerCase() == value.toLowerCase() ||
          s.label.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseStatus.pending,
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
  final String? receiptName, receiptUrl;
  final String? apiStatus;

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
    this.receiptUrl,
    this.apiStatus,
  });

  String get statusLabel =>
      apiStatus == null ? status.label : apiStatus!.replaceAll('_', ' ');

  String get paymentMethodLabel {
    final trimmed = paymentMethod.trim();
    if (trimmed.isEmpty) return 'Bank Transfer';
    switch (trimmed.toLowerCase()) {
      case 'bank_transfer':
      case 'bank transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash';
      case 'credit_card':
      case 'credit card':
        return 'Credit Card';
      case 'debit_card':
      case 'debit card':
        return 'Debit Card';
      case 'mobile_banking':
      case 'mobile banking':
      case 'bkash':
        return 'Mobile Banking';
      default:
        return trimmed
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isEmpty
                ? ''
                : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  String get paidByLabel {
    final trimmed = paidBy.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'nothing') {
      return 'Company Account';
    }
    return trimmed;
  }

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
        'status': apiStatus ?? status.name,
        'vendor': vendor,
        'paidBy': paidBy,
        'notes': notes,
        'receiptName': receiptName,
        'receiptUrl': receiptUrl,
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    final category = {
      'office_rent': 'office',
      'contractors': 'payroll',
      'miscellaneous': 'misc'
    };
    final rawCategory = json['category']?.toString();
    return Expense(
        id: json['id'].toString(),
        title: json['title']?.toString() ?? '',
        amount: num.tryParse(json['amount'].toString())?.toDouble() ?? 0,
        category:
            ExpenseCategory.fromString(category[rawCategory] ?? rawCategory),
        date: DateTime.parse(json['date'].toString()),
        paymentMethod:
            (json['payment_method'] ?? json['paymentMethod'])?.toString() ?? '',
        status: ExpenseStatus.fromString(json['status']?.toString()),
        apiStatus: json['status']?.toString(),
        vendor: json['vendor']?.toString() ?? '',
        paidBy: (json['paid_by'] ?? json['paidBy'])?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        receiptName: (json['receipt_name'] ?? json['receiptName'])?.toString(),
        receiptUrl: (json['receipt_url'] ?? json['receiptUrl'])?.toString());
  }

  Map<String, dynamic> toApi() => {
        'title': title,
        'amount': amount,
        'category': switch (category) {
          ExpenseCategory.office => 'office_rent',
          ExpenseCategory.payroll => 'contractors',
          ExpenseCategory.misc => 'miscellaneous',
          _ => category.name
        },
        'date': date.toIso8601String().split('T').first,
        'payment_method': paymentMethod.toLowerCase().replaceAll(' ', '_'),
        'status': apiStatus ?? status.name,
        'vendor': vendor,
        'paid_by': paidBy,
        'notes': notes
      };

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
        receiptUrl: receiptUrl,
        apiStatus: status == null ? apiStatus : status.name,
      );
}
