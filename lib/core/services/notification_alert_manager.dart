import 'dart:async';
import 'dart:io' show File;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationTone {
  final String key;
  final String title;
  final String subtitle;
  final String? assetPath;
  final String? customFilePath;
  final String? rawResource;
  final String? iosSound;

  const NotificationTone({
    required this.key,
    required this.title,
    required this.subtitle,
    this.assetPath,
    this.customFilePath,
    this.rawResource,
    this.iosSound,
  });
}

/// Central native controller for notification sound, vibration alerts, and custom tones.
class NotificationAlertManager extends ChangeNotifier {
  NotificationAlertManager._();

  static final instance = NotificationAlertManager._();

  static const String keySound = 'nec_notification_sound_enabled_v1';
  static const String keyVibration = 'nec_notification_vibration_enabled_v1';
  static const String keyTone = 'nec_notification_tone_v1';
  static const String keyCustomTonePath =
      'nec_notification_custom_tone_path_v1';
  static const String keyCustomToneTitle =
      'nec_notification_custom_tone_title_v1';

  static const List<NotificationTone> availableTones = [
    NotificationTone(
      key: 'bingi',
      title: 'BinGi Tone (Default)',
      subtitle: 'Signature app chime',
      assetPath: 'sounds/notification.mp3',
      rawResource: 'notification',
      iosSound: 'notification.mp3',
    ),
    NotificationTone(
      key: 'chime',
      title: 'Subtle Chime',
      subtitle: 'Warm three-tone harmonic chime',
      assetPath: 'sounds/chime.wav',
      rawResource: 'chime',
      iosSound: 'chime.wav',
    ),
    NotificationTone(
      key: 'crystal',
      title: 'Crystal Bell',
      subtitle: 'Crisp bright bell alert',
      assetPath: 'sounds/crystal.wav',
      rawResource: 'crystal',
      iosSound: 'crystal.wav',
    ),
    NotificationTone(
      key: 'pulse',
      title: 'Modern Pulse',
      subtitle: 'Soft modern double-tap blip',
      assetPath: 'sounds/pulse.wav',
      rawResource: 'pulse',
      iosSound: 'pulse.wav',
    ),
    NotificationTone(
      key: 'system',
      title: 'System Default',
      subtitle: 'Standard device notification tone',
      assetPath: null,
      rawResource: null,
      iosSound: 'default',
    ),
  ];

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedToneKey = 'bingi';
  String? _customTonePath;
  String? _customToneTitle;
  bool _initialized = false;
  AudioPlayer? _player;

  bool get soundEnabled => _soundEnabled;

  bool get vibrationEnabled => _vibrationEnabled;

  String get selectedToneKey => _selectedToneKey;

  String? get customTonePath => _customTonePath;

  String? get customToneTitle => _customToneTitle;

  bool get hasCustomTone =>
      _customTonePath != null && File(_customTonePath!).existsSync();

  NotificationTone get selectedTone {
    if (_selectedToneKey == 'custom' && hasCustomTone) {
      return NotificationTone(
        key: 'custom',
        title: _customToneTitle ?? 'Custom Tone',
        subtitle: 'From device storage',
        customFilePath: _customTonePath,
      );
    }
    return availableTones.firstWhere(
      (t) => t.key == _selectedToneKey,
      orElse: () => availableTones.first,
    );
  }

  /// Loads persisted sound, vibration, and tone preferences.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(keySound) ?? true;
      _vibrationEnabled = prefs.getBool(keyVibration) ?? true;
      _selectedToneKey = prefs.getString(keyTone) ?? 'bingi';
      _customTonePath = prefs.getString(keyCustomTonePath);
      _customToneTitle = prefs.getString(keyCustomToneTitle);

      if (_customTonePath != null && !File(_customTonePath!).existsSync()) {
        _customTonePath = null;
        _customToneTitle = null;
        if (_selectedToneKey == 'custom') _selectedToneKey = 'bingi';
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationAlertManager] Init error: $e');
    }
  }

  /// Toggles custom notification sound.
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keySound, enabled);
    } catch (e) {
      debugPrint('[NotificationAlertManager] Save sound error: $e');
    }
  }

  /// Toggles device vibration on incoming notification.
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyVibration, enabled);
    } catch (e) {
      debugPrint('[NotificationAlertManager] Save vibration error: $e');
    }
  }

  /// Updates the active notification tone to a preset.
  Future<void> setSelectedToneKey(String key) async {
    _selectedToneKey = key;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyTone, key);
    } catch (e) {
      debugPrint('[NotificationAlertManager] Save tone error: $e');
    }
  }

  /// Sets a custom audio file selected by the user.
  Future<NotificationTone> setCustomTone({
    required String sourcePath,
    required String fileName,
    Uint8List? bytes,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final cleanExt = sourcePath.contains('.')
        ? sourcePath.split('.').last.toLowerCase()
        : 'mp3';
    final destPath = '${dir.path}/custom_notification_tone.$cleanExt';

    if (bytes != null && bytes.isNotEmpty) {
      await File(destPath).writeAsBytes(bytes);
    } else {
      await File(sourcePath).copy(destPath);
    }

    _customTonePath = destPath;
    _customToneTitle = fileName;
    _selectedToneKey = 'custom';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyCustomTonePath, destPath);
      await prefs.setString(keyCustomToneTitle, fileName);
      await prefs.setString(keyTone, 'custom');
    } catch (e) {
      debugPrint('[NotificationAlertManager] Save custom tone error: $e');
    }

    final customTone = selectedTone;
    previewTone(customTone);
    return customTone;
  }

  /// Clears the custom audio file and reverts to the default tone.
  Future<void> clearCustomTone() async {
    try {
      if (_customTonePath != null) {
        final f = File(_customTonePath!);
        if (f.existsSync()) await f.delete();
      }
    } catch (_) {}
    _customTonePath = null;
    _customToneTitle = null;
    _selectedToneKey = 'bingi';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyCustomTonePath);
      await prefs.remove(keyCustomToneTitle);
      await prefs.setString(keyTone, 'bingi');
    } catch (_) {}
  }

  /// Plays a quick preview of any tone.
  Future<void> previewTone(NotificationTone tone) async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      if (tone.customFilePath != null &&
          File(tone.customFilePath!).existsSync()) {
        await _player!.play(
          DeviceFileSource(tone.customFilePath!),
          mode: PlayerMode.lowLatency,
        );
        return;
      }
      if (tone.assetPath != null) {
        _player!.audioCache.prefix = 'assets/';
        await _player!.play(
          AssetSource(tone.assetPath!),
          mode: PlayerMode.lowLatency,
        );
        return;
      }
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('[NotificationAlertManager] Tone preview error: $e');
    }
  }

  /// Triggers sound and vibration according to current user preferences.
  Future<void> triggerAlert(
      {bool forceSound = false, bool forceVibration = false}) async {
    if (!_initialized) {
      await initialize();
    }

    final shouldPlaySound = forceSound || _soundEnabled;
    final shouldVibrate = forceVibration || _vibrationEnabled;

    if (shouldVibrate) {
      _vibrate();
    }

    if (shouldPlaySound) {
      _playSound();
    }
  }

  void _vibrate() {
    try {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 220), () {
        HapticFeedback.vibrate();
      });
    } catch (e) {
      debugPrint('[NotificationAlertManager] Vibration error: $e');
    }
  }

  Future<void> _playSound() async {
    final tone = selectedTone;
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      if (tone.customFilePath != null &&
          File(tone.customFilePath!).existsSync()) {
        await _player!.play(
          DeviceFileSource(tone.customFilePath!),
          mode: PlayerMode.lowLatency,
        );
        return;
      }
      if (tone.assetPath != null) {
        _player!.audioCache.prefix = 'assets/';
        await _player!.play(
          AssetSource(tone.assetPath!),
          mode: PlayerMode.lowLatency,
        );
        return;
      }
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('[NotificationAlertManager] Sound play error: $e');
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
