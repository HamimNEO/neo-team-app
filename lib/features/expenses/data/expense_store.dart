import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../domain/models/expense.dart';
import 'expense_api.dart';

class ExpenseStore extends FrameSafeNotifier {
  ExpenseStore._() {
    _token = _session.accessToken;
    _session.addListener(() {
      if (_token == _session.accessToken) return;
      _token = _session.accessToken;
      _expenses.clear();
      _initialized = false;
      loading = false;
      error = null;
      _loading = null;
      summary = {};
      notifyListeners();
    });
  }

  static final instance = ExpenseStore._();
  final _session = AuthSession.instance;
  late final _api = ExpenseApi(ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => _session.accessToken,
      onUnauthorized: _session.invalidate));
  final _cache = const PreferencesStore();
  final List<Expense> _expenses = [];
  String? _token, error;
  bool _initialized = false, loading = false;
  Future<void>? _loading;
  Map<String, dynamic> summary = {};

  List<Expense> get expenses => List.unmodifiable(_expenses);

  bool get isInitialized => _initialized;

  Future<void> initialize({bool force = false}) {
    if (_token == null || (_initialized && !force)) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final token = _token!, key = 'nec_expenses_api_v1_${_session.user!.id}';
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (!_initialized) {
        try {
          final cached = await _cache.read(key);
          if (cached != null && token == _token) {
            _expenses
              ..clear()
              ..addAll((jsonDecode(cached) as List)
                  .map((r) => Expense.fromJson(Map<String, dynamic>.from(r))));
            notifyListeners();
          }
        } catch (_) {}
      }
      final rows = await _api.list(token);
      if (token != _token) return;
      _expenses
        ..clear()
        ..addAll(rows.map(Expense.fromJson));
      _initialized = true;
      _sortExpenses();
      final now = DateTime.now();
      try {
        final result = await _api.summary(
            token, '${now.year}-${now.month.toString().padLeft(2, '0')}');
        if (token == _token) summary = result;
      } catch (_) {}
      if (token == _token) {
        try {
          await _cache.write(
              key, jsonEncode(_expenses.map((e) => e.toJson()).toList()));
        } catch (_) {}
      }
    } catch (e) {
      if (token == _token) {
        error =
            e is FormatException ? e.message : 'Expenses could not be loaded.';
      }
    } finally {
      if (token == _token) {
        loading = false;
        _loading = null;
        notifyListeners();
      }
    }
  }

  void _sortExpenses() => _expenses.sort((a, b) => b.date.compareTo(a.date));

  Expense? byId(String id) => _expenses.where((e) => e.id == id).firstOrNull;

  Future<void> loadDetail(String id) async {
    final token = _token;
    if (token == null) return;
    final result = await _api.detail(token, id);
    final raw = result['expense'] ?? result['data'] ?? result;
    if (raw is! Map) throw const FormatException('Invalid expense response.');
    if (token != _token) return;
    final item = Expense.fromJson(Map<String, dynamic>.from(raw));
    _expenses.removeWhere((e) => e.id == item.id);
    _expenses.add(item);
    _sortExpenses();
    notifyListeners();
  }

  Future<void> _save(Expense expense, {String? id, ApiUpload? receipt}) async {
    final token = _token;
    if (token == null) throw const FormatException('Please sign in again.');
    final response =
        await _api.save(token, expense.toApi(), id: id, receipt: receipt);
    if (token == _token) {
      final raw = response['expense'] ?? response['data'];
      final savedId = raw is Map ? raw['id']?.toString() : id;
      if (savedId != null) {
        try {
          await loadDetail(savedId);
        } catch (_) {}
      }
    }
    if (token != _token) throw const FormatException('Your account changed.');
    await initialize(force: true);
  }

  Future<void> addExpense(Expense expense, {ApiUpload? receipt}) =>
      _save(expense, receipt: receipt);

  Future<void> updateExpense(Expense expense, {ApiUpload? receipt}) =>
      _save(expense, id: expense.id, receipt: receipt);

  Future<void> deleteExpense(String id) async {
    final token = _token;
    if (token == null) throw const FormatException('Please sign in again.');
    await _api.delete(token, id);
    if (token != _token) return;
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await initialize(force: true);
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
