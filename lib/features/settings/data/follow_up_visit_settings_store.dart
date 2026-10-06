import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/operation_option.dart';

class FollowUpVisitSettingsStore extends ChangeNotifier {
  FollowUpVisitSettingsStore._();

  static final instance = FollowUpVisitSettingsStore._();
  static const _storageKey = 'nec_follow_up_visit_settings_v1';

  final Map<OperationOptionGroup, List<OperationOption>> _options = {
    OperationOptionGroup.followUpMethods: [
      const OperationOption(name: 'Call'),
      const OperationOption(name: 'WhatsApp'),
      const OperationOption(name: 'Email'),
      const OperationOption(name: 'Meeting'),
      const OperationOption(name: 'SMS', isSystem: false),
    ],
    OperationOptionGroup.followUpResults: [
      for (final name in [
        'Interested',
        'Call Later',
        'Need Meeting',
        'Visit Required',
        'Not Interested',
        'No Response',
      ])
        OperationOption(name: name),
    ],
    OperationOptionGroup.visitPurposes: [
      for (final name in [
        'Product Demo',
        'Sales Meeting',
        'Follow-up Meeting',
        'Support Visit',
        'Onboarding',
        'Other',
      ])
        OperationOption(name: name),
    ],
    OperationOptionGroup.visitOutcomes: [
      for (final name in [
        'Interested',
        'Follow-up Required',
        'Proposal Requested',
        'Decision Pending',
        'Not Interested',
      ])
        OperationOption(name: name),
    ],
  };

  Future<void>? _loadFuture;
  Future<void> _pendingSave = Future<void>.value();
  bool _ready = false;

  bool get ready => _ready;

  List<OperationOption> optionsFor(OperationOptionGroup group) =>
      List.unmodifiable(_options[group]!);

  bool contains(OperationOptionGroup group, String name) =>
      _options[group]!.any(
        (option) => option.name.toLowerCase() == name.trim().toLowerCase(),
      );

  Future<void> load() => _loadFuture ??= _restore();

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) {
        final decoded = jsonDecode(saved);
        if (decoded is Map<String, dynamic>) {
          for (final group in OperationOptionGroup.values) {
            final entries = decoded[group.name];
            if (entries is! List) continue;
            final restored = <OperationOption>[];
            for (final entry in entries) {
              if (entry is! Map<String, dynamic>) continue;
              final name = entry['name'];
              if (name is! String || name.trim().isEmpty) continue;
              if (_options[group]!.any(
                (option) =>
                    option.isSystem &&
                    option.name.toLowerCase() == name.trim().toLowerCase(),
              )) {
                continue;
              }
              if (restored.any(
                (option) =>
                    option.name.toLowerCase() == name.trim().toLowerCase(),
              )) {
                continue;
              }
              restored.add(OperationOption(
                name: name.trim(),
                isSystem: false,
                enabled: entry['enabled'] != false,
              ));
            }
            _options[group] = [
              ..._options[group]!.where((option) => option.isSystem),
              ...restored,
            ];
          }
        }
      }
    } catch (_) {
      // Keep the defaults available if local storage is unavailable.
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  bool add(OperationOptionGroup group, String name) {
    final trimmed = name.trim();
    if (!_ready || trimmed.isEmpty || contains(group, trimmed)) return false;
    _options[group]!.add(OperationOption(name: trimmed, isSystem: false));
    _changed();
    return true;
  }

  void toggle(OperationOptionGroup group, OperationOption option, bool value) {
    if (!_ready || option.isSystem) return;
    final index = _options[group]!.indexOf(option);
    if (index < 0) return;
    _options[group]![index] = option.withEnabled(value);
    _changed();
  }

  void remove(OperationOptionGroup group, OperationOption option) {
    if (!_ready || option.isSystem) return;
    _options[group]!.remove(option);
    _changed();
  }

  void _changed() {
    notifyListeners();
    final payload = jsonEncode({
      for (final group in OperationOptionGroup.values)
        group.name: [
          for (final option in _options[group]!)
            {'name': option.name, 'enabled': option.enabled},
        ],
    });
    _pendingSave = _pendingSave.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, payload);
      } catch (_) {
        // Changes remain available in memory for this session.
      }
    });
    unawaited(_pendingSave);
  }
}
