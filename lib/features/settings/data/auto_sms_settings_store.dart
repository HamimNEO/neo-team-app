import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoSmsSettingsStore extends ChangeNotifier {
  AutoSmsSettingsStore._();

  static final instance = AutoSmsSettingsStore._();
  static const _storageKey = 'nec_auto_sms_settings_v1';

  bool _isAutoSmsEnabled = true;
  String _triggerTiming = '15 minutes before';
  String _recipientTarget = 'Client Contact';
  String _senderId = 'NEONECY-CRM';
  String _testPhoneNumber = '+880 1711-223344';
  int _totalDispatched = 37;

  String _smsTemplate =
      'Hello {client_name}, this is a reminder from NEONECY regarding your scheduled {purpose} on {date} at {time}. Representative: {rep_name}.';

  Future<void>? _loadFuture;
  bool _ready = false;

  bool get ready => _ready;

  bool get isAutoSmsEnabled => _isAutoSmsEnabled;

  String get triggerTiming => _triggerTiming;

  String get recipientTarget => _recipientTarget;

  String get senderId => _senderId;

  String get smsTemplate => _smsTemplate;

  String get testPhoneNumber => _testPhoneNumber;

  int get totalDispatched => _totalDispatched;

  static const List<String> timingOptions = [
    'Immediately on creation',
    '15 minutes before',
    '30 minutes before',
    '1 hour before',
    'On scheduled time',
  ];

  static const List<String> recipientOptions = [
    'Client Contact',
    'Assigned Representative',
    'Both (Client & Rep)',
  ];

  static const List<String> availableTokens = [
    '{client_name}',
    '{date}',
    '{time}',
    '{purpose}',
    '{rep_name}',
    '{company}',
  ];

  Future<void> load() => _loadFuture ??= _restore();

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAutoSmsEnabled = prefs.getBool('${_storageKey}_enabled') ?? true;
      _triggerTiming =
          prefs.getString('${_storageKey}_timing') ?? '15 minutes before';
      _recipientTarget =
          prefs.getString('${_storageKey}_recipient') ?? 'Client Contact';
      _smsTemplate = prefs.getString('${_storageKey}_template') ?? _smsTemplate;
      _senderId = prefs.getString('${_storageKey}_sender_id') ?? 'NEONECY-CRM';
      _totalDispatched = prefs.getInt('${_storageKey}_total_dispatched') ?? 37;
    } catch (_) {
      // Use defaults
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_storageKey}_enabled', _isAutoSmsEnabled);
      await prefs.setString('${_storageKey}_timing', _triggerTiming);
      await prefs.setString('${_storageKey}_recipient', _recipientTarget);
      await prefs.setString('${_storageKey}_template', _smsTemplate);
      await prefs.setString('${_storageKey}_sender_id', _senderId);
      await prefs.setInt('${_storageKey}_total_dispatched', _totalDispatched);
    } catch (_) {}
  }

  void toggleAutoSms(bool value) {
    _isAutoSmsEnabled = value;
    notifyListeners();
    unawaited(_save());
  }

  void setTriggerTiming(String timing) {
    if (_triggerTiming != timing) {
      _triggerTiming = timing;
      notifyListeners();
      unawaited(_save());
    }
  }

  void setRecipientTarget(String target) {
    if (_recipientTarget != target) {
      _recipientTarget = target;
      notifyListeners();
      unawaited(_save());
    }
  }

  void setTemplate(String template) {
    if (_smsTemplate != template) {
      _smsTemplate = template;
      notifyListeners();
      unawaited(_save());
    }
  }

  void setTestPhoneNumber(String phone) {
    _testPhoneNumber = phone;
    notifyListeners();
  }

  void recordSimulatedDispatch() {
    _totalDispatched++;
    notifyListeners();
    unawaited(_save());
  }

  void resetToDefaultTemplate() {
    _smsTemplate =
        'Hello {client_name}, this is a reminder from NEONECY regarding your scheduled {purpose} on {date} at {time}. Representative: {rep_name}.';
    notifyListeners();
    unawaited(_save());
  }

  String formatTemplate({
    required String clientName,
    required String date,
    required String time,
    required String purpose,
    required String repName,
  }) {
    return _smsTemplate
        .replaceAll('{client_name}', clientName)
        .replaceAll('{date}', date)
        .replaceAll('{time}', time)
        .replaceAll('{purpose}', purpose)
        .replaceAll('{rep_name}', repName)
        .replaceAll('{company}', 'NEONECY Hospitality PMS');
  }
}
