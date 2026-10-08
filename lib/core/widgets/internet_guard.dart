import 'package:flutter/material.dart';

import '../../features/connectivity/presentation/no_internet_screen.dart';
import '../services/internet_service.dart';

/// Covers the entire navigator, including sheets, without replacing its routes.
class InternetGuard extends StatefulWidget {
  const InternetGuard({
    super.key,
    required this.child,
    this.onFirstConnection,
  });

  final Widget child;
  final VoidCallback? onFirstConnection;

  @override
  State<InternetGuard> createState() => _InternetGuardState();
}

class _InternetGuardState extends State<InternetGuard>
    with WidgetsBindingObserver {
  final InternetService _internet = InternetService.instance;
  bool _wasConnected = false;
  bool _didConnect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _internet.addListener(_handleConnection);
    _internet.start();
  }

  void _handleConnection() {
    if (_wasConnected && !_internet.isConnected) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _wasConnected = _internet.isConnected;
    if (_internet.isConnected && !_didConnect) {
      _didConnect = true;
      widget.onFirstConnection?.call();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _internet.start();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _internet.stop();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Future<bool> didPopRoute() async => !_internet.isConnected;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _internet.removeListener(_handleConnection);
    _internet.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _internet,
      builder: (context, _) {
        final blocked = !_internet.isConnected;
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              ignoring: blocked,
              child: ExcludeSemantics(
                excluding: blocked,
                child: TickerMode(enabled: !blocked, child: widget.child),
              ),
            ),
            if (blocked)
              NoInternetScreen(
                initialCheck:
                    _internet.state == InternetConnectionState.checking,
                isChecking: _internet.isChecking,
                onRetry: _internet.recheck,
              ),
          ],
        );
      },
    );
  }
}
