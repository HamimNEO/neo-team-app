import 'package:flutter/services.dart';
import '../../features/settings/data/user_settings_store.dart';

/// Centralized native haptic feedback helper that strictly respects the
/// user's 'Haptic Feedback' switch preference.
class AppHaptics {
  AppHaptics._();

  /// Whether haptic effects are enabled in user settings.
  static bool get isEnabled => UserSettingsStore.instance.hapticFeedback;

  /// Subtle click for button taps, switches, tab selection.
  static void lightImpact() {
    if (isEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Medium pulse for meaningful state changes or actions.
  static void mediumImpact() {
    if (isEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Heavy impact for confirmations, deletions, or status transitions.
  static void heavyImpact() {
    if (isEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Picker / slider tick.
  static void selectionClick() {
    if (isEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Standard native vibration pulse.
  static void vibrate() {
    if (isEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
