import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/expense.dart';
import 'mock_expenses.dart';

class ExpenseStore extends ChangeNotifier {
  ExpenseStore._();

  static final ExpenseStore instance = ExpenseStore._();

  static const _prefKey = 'neonecy_expenses_store_v1';

  final List<Expense> _expenses = [];
  bool _initialized = false;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data);
        _expenses.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _expenses.add(Expense.fromJson(item));
          }
        }
      } else {
        _expenses.clear();
        _expenses.addAll(mockExpenses);
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      if (_expenses.isEmpty) {
        _expenses.addAll(mockExpenses);
      }
    }
    _sortExpenses();
    _initialized = true;
    notifyListeners();
  }

  void _sortExpenses() {
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _expenses.map((e) => e.toJson()).toList();
      await prefs.setString(_prefKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error persisting expenses: $e');
    }
  }

  Expense? byId(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.insert(0, expense);
    _sortExpenses();
    notifyListeners();
    await _persist();
  }

  Future<void> updateExpense(Expense expense) async {
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      _expenses[idx] = expense;
      _sortExpenses();
      notifyListeners();
      await _persist();
    }
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  double get totalExpensesOverall {
    return _expenses.fold(0.0, (acc, e) => acc + e.amount);
  }

  double totalExpensesForMonth(int year, int month) {
    return _expenses
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  double get totalThisMonth {
    final now = DateTime.now();
    return totalExpensesForMonth(now.year, now.month);
  }

  double get totalPaidThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.status == ExpenseStatus.paid)
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  double get totalPendingThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.status != ExpenseStatus.paid)
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  Map<ExpenseCategory, double> get categoryBreakdownThisMonth {
    final now = DateTime.now();
    final Map<ExpenseCategory, double> map = {};
    for (final e in _expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        map[e.category] = (map[e.category] ?? 0.0) + e.amount;
      }
    }
    return map;
  }
}
