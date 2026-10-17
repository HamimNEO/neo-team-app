import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import 'notification_service.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  FirebaseAnalytics? _analytics;
  Future<void>? _initializing;
  Timer? _retry;
  int _attempts = 0;

  FirebaseAnalytics? get analytics => _analytics;

  /// Initializes Firebase, Crashlytics, Analytics, and Notifications
  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      debugPrint('[FirebaseService] Firebase initialized successfully');

      await NotificationService.instance.initialize();
      _retry?.cancel();
      _attempts = 0;
    } catch (error) {
      _initializing = null;
      final code = error is FirebaseException ? error.code : 'initialization';
      debugPrint('[FirebaseService] Push initialization failed ($code).');
      NotificationService.instance.status.value =
          'Unable to connect notifications. Retrying…';
      if (_attempts < 6 && !(_retry?.isActive ?? false)) {
        final seconds = 5 * (1 << _attempts++);
        _retry = Timer(Duration(seconds: seconds > 120 ? 120 : seconds), () {
          initialize().ignore();
        });
      }
      return;
    }

    try {
      _analytics = FirebaseAnalytics.instance;

      if (!kIsWeb) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;

        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };

        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
      }
    } catch (_) {
      debugPrint('[FirebaseService] Optional analytics setup unavailable.');
    }
  }

  /// Log a custom analytics event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('[FirebaseService] Failed to log event $name: $e');
    }
  }

  /// Set user ID across Analytics and Crashlytics
  Future<void> setUserId(String userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      }
    } catch (e) {
      debugPrint('[FirebaseService] Failed to set user ID: $e');
    }
  }
}
