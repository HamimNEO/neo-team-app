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

  FirebaseAnalytics? get analytics => _analytics;

  /// Initializes Firebase, Crashlytics, Analytics, and Notifications
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[FirebaseService] Firebase initialized successfully');

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

      await NotificationService.instance.initialize();
    } catch (e, stack) {
      debugPrint('[FirebaseService] Initialization failed: $e\n$stack');
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
