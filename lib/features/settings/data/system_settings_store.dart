import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/system_settings.dart';

class SystemSettingsStore extends ChangeNotifier {
  SystemSettingsStore._();

  static final instance = SystemSettingsStore._();
  static const _storageKey = 'nec_system_settings_v1';

  SystemSettings _value = const SystemSettings();
  Future<void>? _loadFuture;
  Future<void> _pendingWrite = Future<void>.value();
  bool _ready = false;

  SystemSettings get value => _value;

  bool get ready => _ready;

  Future<void> load() => _loadFuture ??= _restore();

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) {
        final decoded = jsonDecode(saved);
        if (decoded is Map<String, dynamic>) {
          _value = SystemSettings.fromJson(decoded);
        }
      }
    } catch (_) {
      // Keep the initial defaults if saved settings cannot be read.
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<bool> update(SystemSettings Function(SystemSettings) transform) async {
    await load();
    final previous = _value;
    final next = transform(previous);
    final payload = jsonEncode(next.toJson());
    _value = next;
    notifyListeners();

    final write = _pendingWrite.then<bool>((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setString(_storageKey, payload);
      } catch (_) {
        return false;
      }
    });
    _pendingWrite = write.then<void>((_) {});
    final saved = await write;
    if (!saved && identical(_value, next)) {
      _value = previous;
      notifyListeners();
    }
    return saved;
  }
}
