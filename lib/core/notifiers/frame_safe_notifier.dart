import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Stores can load during initState without rebuilding other mounted screens
/// while Flutter is building the current frame.
class FrameSafeNotifier extends ChangeNotifier {
  bool _queued = false, _disposed = false;

  @override
  void notifyListeners() {
    if (_disposed) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_queued) return;
      _queued = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _queued = false;
        if (!_disposed) super.notifyListeners();
      });
    } else {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
