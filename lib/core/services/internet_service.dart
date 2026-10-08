import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

enum InternetConnectionState { checking, connected, disconnected }

/// Checks real internet reachability, including Wi-Fi with no internet access.
class InternetService extends ChangeNotifier {
  InternetService._();

  static final InternetService instance = InternetService._();

  final InternetConnection _connection = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 3),
  );
  StreamSubscription<InternetStatus>? _subscription;
  InternetConnectionState _state = InternetConnectionState.checking;
  bool _checking = false;
  int _revision = 0;

  InternetConnectionState get state => _state;

  bool get isConnected => _state == InternetConnectionState.connected;

  bool get isChecking => _checking;

  void start() {
    if (_subscription != null) return;
    _state = InternetConnectionState.checking;
    _subscription = _connection.onStatusChange.listen(
      (status) {
        _revision++;
        _setConnected(status == InternetStatus.connected);
      },
      onError: (Object error, StackTrace stack) {
        _revision++;
        _setConnected(false);
      },
    );
    unawaited(recheck());
  }

  Future<void> recheck() async {
    if (_checking || _subscription == null) return;
    final revision = ++_revision;
    _checking = true;
    notifyListeners();
    var connected = false;
    try {
      connected = await _connection.hasInternetAccess.timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {
      connected = false;
    }
    if (_subscription != null && revision == _revision) {
      _setConnected(connected);
    }
  }

  void _setConnected(bool connected) {
    final next = connected
        ? InternetConnectionState.connected
        : InternetConnectionState.disconnected;
    if (_state == next && !_checking) return;
    _state = next;
    _checking = false;
    notifyListeners();
  }

  void stop() {
    _revision++;
    final subscription = _subscription;
    _subscription = null;
    _checking = false;
    if (subscription != null) unawaited(subscription.cancel());
  }

  @override
  void dispose() {
    stop();
    unawaited(_connection.dispose());
    super.dispose();
  }
}
