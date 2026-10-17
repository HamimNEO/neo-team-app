import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/controllers/auth_session.dart';
import '../../features/leads/data/lead_store.dart';
import '../../features/messages/data/group_chat_store.dart';
import '../../features/messages/data/message_store.dart';
import '../../features/more/data/datasources/notification_api.dart';
import '../../features/more/data/notification_store.dart';
import '../../features/tasks/data/work_item_store.dart';
import '../../features/team/domain/models/employee.dart';
import '../config/app_config.dart';
import '../diagnostics/push_debug.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../router/app_router.dart';
import 'notification_alert_manager.dart';
import 'notification_target.dart';
import 'package_service.dart';

const _channel = _channelLegacy;

const _channelLegacy = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Assignments, reminders and team notifications.',
  importance: Importance.max,
);

final _channelSoundVibe = AndroidNotificationChannel(
  'high_importance_channel_v2',
  'Team Notifications (BinGi Tone)',
  description: 'Team alerts with custom sound tone and vibration.',
  importance: Importance.max,
  playSound: true,
  sound: const RawResourceAndroidNotificationSound('notification'),
  enableVibration: true,
  vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
);

const _channelSoundOnly = AndroidNotificationChannel(
  'high_importance_channel_sound_only',
  'Team Notifications (BinGi Tone - Sound Only)',
  description: 'Team alerts with custom sound tone.',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('notification'),
  enableVibration: false,
);

final _channelChimeVibe = AndroidNotificationChannel(
  'high_importance_channel_chime',
  'Team Notifications (Subtle Chime)',
  description: 'Team alerts with chime tone and vibration.',
  importance: Importance.max,
  playSound: true,
  sound: const RawResourceAndroidNotificationSound('chime'),
  enableVibration: true,
  vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
);

const _channelChimeOnly = AndroidNotificationChannel(
  'high_importance_channel_chime_only',
  'Team Notifications (Subtle Chime - Sound Only)',
  description: 'Team alerts with chime tone.',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('chime'),
  enableVibration: false,
);

final _channelCrystalVibe = AndroidNotificationChannel(
  'high_importance_channel_crystal',
  'Team Notifications (Crystal Bell)',
  description: 'Team alerts with crystal bell tone and vibration.',
  importance: Importance.max,
  playSound: true,
  sound: const RawResourceAndroidNotificationSound('crystal'),
  enableVibration: true,
  vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
);

const _channelCrystalOnly = AndroidNotificationChannel(
  'high_importance_channel_crystal_only',
  'Team Notifications (Crystal Bell - Sound Only)',
  description: 'Team alerts with crystal bell tone.',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('crystal'),
  enableVibration: false,
);

final _channelPulseVibe = AndroidNotificationChannel(
  'high_importance_channel_pulse',
  'Team Notifications (Modern Pulse)',
  description: 'Team alerts with pulse tone and vibration.',
  importance: Importance.max,
  playSound: true,
  sound: const RawResourceAndroidNotificationSound('pulse'),
  enableVibration: true,
  vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
);

const _channelPulseOnly = AndroidNotificationChannel(
  'high_importance_channel_pulse_only',
  'Team Notifications (Modern Pulse - Sound Only)',
  description: 'Team alerts with pulse tone.',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('pulse'),
  enableVibration: false,
);

const _channelSystemVibe = AndroidNotificationChannel(
  'high_importance_channel_system',
  'Team Notifications (System Default)',
  description: 'Team alerts with system sound and vibration.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

const _channelSystemOnly = AndroidNotificationChannel(
  'high_importance_channel_system_only',
  'Team Notifications (System Default - Sound Only)',
  description: 'Team alerts with system sound.',
  importance: Importance.max,
  playSound: true,
  enableVibration: false,
);

final _channelVibeOnly = AndroidNotificationChannel(
  'high_importance_channel_vibe_only',
  'Team Notifications (Vibration Only)',
  description: 'Team alerts with vibration.',
  importance: Importance.max,
  playSound: false,
  enableVibration: true,
  vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
);

const _channelSilent = AndroidNotificationChannel(
  'high_importance_channel_silent',
  'Team Notifications (Silent)',
  description: 'Silent team alerts.',
  importance: Importance.max,
  playSound: false,
  enableVibration: false,
);

final _allNotificationChannels = [
  _channelLegacy,
  _channelSoundVibe,
  _channelSoundOnly,
  _channelChimeVibe,
  _channelChimeOnly,
  _channelCrystalVibe,
  _channelCrystalOnly,
  _channelPulseVibe,
  _channelPulseOnly,
  _channelSystemVibe,
  _channelSystemOnly,
  _channelVibeOnly,
  _channelSilent,
];

AndroidNotificationChannel _getTargetChannel(
    NotificationTone tone, bool soundEnabled, bool vibrationEnabled) {
  if (!soundEnabled && !vibrationEnabled) {
    return _channelSilent;
  }
  if (!soundEnabled && vibrationEnabled) {
    return _channelVibeOnly;
  }
  return switch (tone.key) {
    'chime' => vibrationEnabled ? _channelChimeVibe : _channelChimeOnly,
    'crystal' => vibrationEnabled ? _channelCrystalVibe : _channelCrystalOnly,
    'pulse' => vibrationEnabled ? _channelPulseVibe : _channelPulseOnly,
    'system' => vibrationEnabled ? _channelSystemVibe : _channelSystemOnly,
    _ => vibrationEnabled ? _channelSoundVibe : _channelSoundOnly,
  };
}

const _localSettings = InitializationSettings(
  android: AndroidInitializationSettings('@drawable/ic_notification'),
  iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false),
  macOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false),
);

void _traceMessage(String event, RemoteMessage message) {
  PushDebug.log(event, {
    'message_id': message.messageId,
    'sent_at': message.sentTime?.toUtc().toIso8601String(),
    'ttl_seconds': message.ttl,
    'has_notification_payload': message.notification != null,
    'android_channel': message.notification?.android?.channelId,
    'data_keys': message.data.keys.toList(),
    ...PushDebug.metadata(message.data),
  });
}

/// Group photos are stored as hidden chat messages; never notify for them.
bool isGroupAvatarSystemText(String? text) {
  final t = text?.trim().toLowerCase() ?? '';
  return t.startsWith('[group avatar') || t.startsWith('[avatar:');
}

Future<bool> _remember(RemoteMessage message, {String? identity}) async {
  final key = identity ??
      message.data['notification_id']?.toString() ??
      message.messageId;
  if (key == null) return true;
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final seen = prefs.getStringList('nec_push_seen_v1') ?? [];
  if (seen.contains(key)) {
    PushDebug.log('display.skipped', {
      'reason': 'duplicate_notification',
      'key': key,
      'message_id': message.messageId,
    });
    return false;
  }
  seen.add(key);
  await prefs.setStringList('nec_push_seen_v1',
      seen.length > 100 ? seen.sublist(seen.length - 100) : seen);
  return true;
}

bool _recipientMatches(Map<String, dynamic> data, Map user) {
  final recipient = data['recipient_user_id'] ?? data['user_id'];
  final employee = data['recipient_employee_id'];
  final matches = (recipient == null ||
          '$recipient' == '${user['id']}' ||
          'usr_$recipient' == '${user['id']}') &&
      (employee == null ||
          '$employee' ==
              '${user['employee_id'] ?? (user['employee'] is Map ? user['employee']['id'] : null)}');
  if (!matches) {
    PushDebug.log('display.skipped', {
      'reason': 'recipient_mismatch',
      'current_user_id': user['id']?.toString(),
      'current_employee_id': (user['employee_id'] ??
              (user['employee'] is Map ? user['employee']['id'] : null))
          ?.toString(),
      ...PushDebug.metadata(data),
    });
  }
  return matches;
}

Future<void> _display(
    FlutterLocalNotificationsPlugin local, RemoteMessage message) async {
  var title = message.notification?.title ?? message.data['title']?.toString();
  var body = message.notification?.body ?? message.data['body']?.toString();
  if (title != null) {
    title = title
        .replaceAll(
            RegExp(r'\s*\[\d{1,2}:\d{2}(\s*(?:AM|PM|am|pm))?\]',
                caseSensitive: false),
            '')
        .trim();
  }
  if (body != null) {
    body = body
        .replaceAll(
            RegExp(r'\s*\[\d{1,2}:\d{2}(\s*(?:AM|PM|am|pm))?\]',
                caseSensitive: false),
            '')
        .trim();
    if (body.toLowerCase() == '[attachment]') {
      body = 'Sent an attachment';
    } else {
      body = body
          .replaceAll(RegExp(r'\[attachment\]', caseSensitive: false),
              'Sent an attachment')
          .trim();
    }
    if (body.isEmpty) {
      body = 'Sent an attachment';
    }
  }
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    PushDebug.log('display.skipped', {
      'reason': 'missing_title_and_body',
      'message_id': message.messageId,
    });
    return;
  }
  if (isGroupAvatarSystemText(body) || isGroupAvatarSystemText(title)) {
    PushDebug.log('display.skipped', {
      'reason': 'group_avatar_system_message',
      'message_id': message.messageId,
    });
    return;
  }
  final identity = message.data['notification_id']?.toString() ??
      message.messageId ??
      '$title|$body';
  if (!await _remember(message, identity: identity)) return;
  final digest = sha256.convert(utf8.encode(identity)).bytes;
  final id =
      ((digest[0] << 24) | (digest[1] << 16) | (digest[2] << 8) | digest[3]) &
          0x7fffffff;
  final prefs = await SharedPreferences.getInstance();
  final soundEnabled = prefs.getBool(NotificationAlertManager.keySound) ?? true;
  final vibrationEnabled =
      prefs.getBool(NotificationAlertManager.keyVibration) ?? true;
  final toneKey = prefs.getString(NotificationAlertManager.keyTone) ?? 'bingi';
  final tone = NotificationAlertManager.availableTones.firstWhere(
    (t) => t.key == toneKey,
    orElse: () => NotificationAlertManager.availableTones.first,
  );

  final targetChannel = _getTargetChannel(tone, soundEnabled, vibrationEnabled);

  PushDebug.log('display.requested', {
    'message_id': message.messageId,
    'local_notification_id': id,
    'channel_id': targetChannel.id,
    'tone_key': tone.key,
    'sound_enabled': soundEnabled,
    'vibration_enabled': vibrationEnabled,
    'has_title': title?.isNotEmpty ?? false,
    'has_body': body?.isNotEmpty ?? false,
  });
  await local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          targetChannel.id,
          targetChannel.name,
          channelDescription: targetChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          playSound: soundEnabled,
          sound: soundEnabled && tone.rawResource != null
              ? RawResourceAndroidNotificationSound(tone.rawResource!)
              : null,
          enableVibration: vibrationEnabled,
          vibrationPattern:
              vibrationEnabled ? Int64List.fromList([0, 250, 250, 250]) : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: soundEnabled,
          sound: soundEnabled ? tone.iosSound : null,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: soundEnabled,
          sound: soundEnabled ? tone.iosSound : null,
        ),
      ),
      payload: jsonEncode(message.data));
  PushDebug.log('display.submitted_to_os', {
    'message_id': message.messageId,
    'local_notification_id': id,
    'note': 'Plugin accepted display request; OS settings control visibility.',
  });
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _traceMessage('fcm.received.background', message);
  if (message.notification != null) {
    PushDebug.log('display.handled_by_os', {
      'message_id': message.messageId,
      'reason': 'background_notification_payload',
    });
    return;
  }
  try {
    await Firebase.initializeApp();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString('nec_auth_session_v1');
    if (raw == null) {
      PushDebug.log('display.skipped', {'reason': 'no_cached_session'});
      return;
    }
    final session = jsonDecode(raw) as Map;
    final expiry = DateTime.tryParse(session['expires_at']?.toString() ?? '');
    if (expiry == null || !expiry.isAfter(DateTime.now())) {
      PushDebug.log('display.skipped', {'reason': 'cached_session_expired'});
      return;
    }
    if (session['user'] is! Map ||
        !_recipientMatches(message.data, session['user'] as Map)) {
      if (session['user'] is! Map) {
        PushDebug.log('display.skipped', {'reason': 'invalid_cached_user'});
      }
      return;
    }
    final local = FlutterLocalNotificationsPlugin();
    await local.initialize(settings: _localSettings);
    final androidPlugin = local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in _allNotificationChannels) {
      await androidPlugin?.createNotificationChannel(channel);
    }
    await _display(local, message);
  } catch (error) {
    PushDebug.log('background.failed', {
      'message_id': message.messageId,
      'error_type': error.runtimeType.toString(),
      if (error is FirebaseException) 'firebase_code': error.code,
      if (error is PlatformException) 'platform_code': error.code,
    });
    rethrow;
  }
}

class NotificationService with WidgetsBindingObserver {
  NotificationService._();

  static final instance = NotificationService._();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  final _deviceApi =
      NotificationApi(ApiClient(baseUrl: () => AppConfig.apiBaseUrl));
  Future<void>? _initializing;
  Future<void> _binding = Future.value();
  bool _ready = false, _loggingOut = false;
  String? _fcmToken, _authToken, _registeredAuth, _registeredFcm, _pendingRoute;
  String? registrationError;
  final status = ValueNotifier<String>('Connecting notifications…');
  Timer? _registrationRetry;
  int _registrationAttempts = 0;
  Future<void>? _refreshing;
  Timer? _appleRetry;
  int _appleAttempts = 0;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_ready) return refreshRegistration();
    try {
      await (_initializing ??= _initialize());
    } catch (error) {
      PushDebug.log('service.initialization_failed', {
        'error_type': error.runtimeType.toString(),
        if (error is FirebaseException) 'firebase_code': error.code,
        if (error is PlatformException) 'platform_code': error.code,
      });
      _initializing = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    PushDebug.log('service.initializing', {
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'channel_id': _channel.id,
      'project_id': Firebase.app().options.projectId,
      'sender_id': Firebase.app().options.messagingSenderId,
      'user_id': AuthSession.instance.user?.id,
      'employee_id': AuthSession.instance.user?.employeeId,
    });
    if (kIsWeb) {
      registrationError =
          'Web push requires VAPID and a messaging service worker.';
      return;
    }
    try {
      tz.initializeTimeZones();
    } catch (_) {}
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _local.initialize(
        settings: _localSettings,
        onDidReceiveNotificationResponse: (response) {
          PushDebug.log('local_notification.tapped', {
            'local_notification_id': response.id,
            'has_payload': response.payload != null,
          });
          if (response.payload == null) return;
          try {
            _open(Map<String, dynamic>.from(
                jsonDecode(response.payload!) as Map));
          } catch (error) {
            PushDebug.log('navigation.invalid_payload',
                {'error_type': error.runtimeType.toString()});
          }
        });
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      for (final channel in _allNotificationChannels) {
        await androidPlugin?.createNotificationChannel(channel);
      }
      if (kDebugMode) {
        try {
          final enabled = await androidPlugin?.areNotificationsEnabled();
          final channels = await androidPlugin?.getNotificationChannels();
          final matched =
              channels?.where((channel) => channel.id == _channelSoundVibe.id);
          PushDebug.log('android.channel', {
            'phase': 'before_permission_request',
            'notifications_enabled': enabled,
            'channel_id': _channelSoundVibe.id,
            'channel_importance': matched != null && matched.isNotEmpty
                ? matched.first.importance.name
                : null,
          });
        } catch (error) {
          PushDebug.log('android.channel_diagnostic_failed',
              {'error_type': error.runtimeType.toString()});
        }
      }
    }
    await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);
    _fcm.onTokenRefresh.listen((token) {
      PushDebug.log('fcm.token_refreshed', {
        'old_fcm_fingerprint': PushDebug.fingerprint(_fcmToken),
        'new_fcm_fingerprint': PushDebug.fingerprint(token),
        'user_id': AuthSession.instance.user?.id,
        'employee_id': AuthSession.instance.user?.employeeId,
      });
      _fcmToken = token;
      if (kDebugMode) {
        debugPrint('[Notifications] FCM device token: $token');
      }
      _syncRegistration().ignore();
    });
    FirebaseMessaging.onMessage.listen((message) async {
      _traceMessage('fcm.received.foreground', message);
      if (!AuthSession.instance.signedIn) {
        PushDebug.log('display.skipped',
            {'reason': 'not_signed_in', 'message_id': message.messageId});
        return;
      }
      final user = AuthSession.instance.user!;
      if (!_recipientMatches(
          message.data, {'id': user.id, 'employee_id': user.employeeId})) {
        return;
      }
      final nativeApple = !kIsWeb &&
          (Platform.isIOS || Platform.isMacOS) &&
          message.notification != null;
      try {
        if (nativeApple) {
          PushDebug.log('display.handled_by_os', {
            'message_id': message.messageId,
            'reason': 'apple_foreground_presentation'
          });
        }
        if (!kIsWeb && !nativeApple) await _display(_local, message);
        // Play notification sound and vibrate natively according to user settings
        NotificationAlertManager.instance.triggerAlert().ignore();
        _refreshData();
      } catch (error) {
        PushDebug.log('display.failed', {
          'message_id': message.messageId,
          'error_type': error.runtimeType.toString(),
          if (error is PlatformException) 'platform_code': error.code,
        });
        debugPrint('[Notifications] Could not display incoming notification.');
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _traceMessage('fcm.notification_tapped', message);
      _open(message.data);
    });
    AuthSession.instance.addListener(_sessionChanged);
    AuthSession.instance.beforeSignOut = _unregister;
    WidgetsBinding.instance.addObserver(this);
    _ready = true;
    _authToken = AuthSession.instance.accessToken;
    try {
      await requestPermission();
    } catch (error) {
      PushDebug.log('permission.request_failed',
          {'error_type': error.runtimeType.toString()});
      registrationError =
          'Allow notifications in device settings to receive push alerts.';
    }
    await refreshRegistration();
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      _traceMessage('fcm.opened_from_terminated', initial);
      _open(initial.data);
    }
    final localInitial = await _local.getNotificationAppLaunchDetails();
    final payload = localInitial?.notificationResponse?.payload;
    if (localInitial?.didNotificationLaunchApp == true && payload != null) {
      try {
        _open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
      } catch (_) {}
    }
  }

  Future<NotificationSettings> requestPermission() async {
    final settings =
        await _fcm.requestPermission(alert: true, badge: true, sound: true);
    PushDebug.log('permission.result',
        {'authorization': settings.authorizationStatus.name});
    return settings;
  }

  void _sessionChanged() {
    final token = AuthSession.instance.accessToken;
    if (_authToken == token) return;
    PushDebug.log('session.changed', {
      'signed_in': AuthSession.instance.signedIn,
      'user_id': AuthSession.instance.user?.id,
      'employee_id': AuthSession.instance.user?.employeeId,
      'is_admin': AuthSession.instance.user?.isSuperAdmin,
    });
    _authToken = token;
    _loggingOut = false;
    _registrationRetry?.cancel();
    _registrationAttempts = 0;
    _local.cancelAll().ignore();
    if (token == null) {
      _pendingRoute = null;
      _syncRegistration();
    } else {
      refreshRegistration();
      _flushRoute();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    PushDebug.log('app.lifecycle', {'state': state.name});
    if (state == AppLifecycleState.resumed) {
      _registrationAttempts = 0;
      refreshRegistration();
    } else if (state == AppLifecycleState.paused) {
      _registrationRetry?.cancel();
    }
  }

  Future<void> refreshRegistration() async {
    if (_refreshing != null) return _refreshing;
    final pending = _refreshRegistration();
    _refreshing = pending;
    try {
      await pending;
    } finally {
      _refreshing = null;
    }
  }

  Future<void> _refreshRegistration() async {
    if (!_ready || _loggingOut) {
      PushDebug.log('registration.skipped',
          {'reason': !_ready ? 'service_not_ready' : 'signing_out'});
      return;
    }
    try {
      final settings = await _fcm.getNotificationSettings();
      PushDebug.log('registration.check', {
        'authorization': settings.authorizationStatus.name,
        'user_id': AuthSession.instance.user?.id,
        'employee_id': AuthSession.instance.user?.employeeId,
        'is_admin': AuthSession.instance.user?.isSuperAdmin,
      });
      if (![AuthorizationStatus.authorized, AuthorizationStatus.provisional]
          .contains(settings.authorizationStatus)) {
        registrationError = 'Allow notifications in device settings.';
        status.value = registrationError!;
        PushDebug.log('registration.skipped', {'reason': 'permission_denied'});
        return;
      }
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        if (await _fcm.getAPNSToken() == null) {
          registrationError = 'Waiting for the Apple push token.';
          PushDebug.log(
              'registration.skipped', {'reason': 'waiting_for_apns_token'});
          if (_appleAttempts < 10 && !(_appleRetry?.isActive ?? false)) {
            _appleRetry = Timer(const Duration(seconds: 3), () {
              _appleAttempts++;
              refreshRegistration();
            });
          }
          return;
        }
      }
      if (kIsWeb) {
        registrationError =
            'Web push requires VAPID and a messaging service worker.';
        return;
      }
      _fcmToken = await _fcm.getToken();
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        _registrationFailed('Firebase has not issued a device token yet.');
        return;
      }
      if (kDebugMode) {
        debugPrint('[Notifications] FCM device token: $_fcmToken');
      }
      PushDebug.log('fcm.token_available',
          {'fcm_fingerprint': PushDebug.fingerprint(_fcmToken)});
      await _syncRegistration();
    } on FirebaseException catch (error) {
      PushDebug.log('registration.failed', {'firebase_code': error.code});
      _registrationFailed('Firebase connection failed (${error.code}).');
    } catch (error) {
      PushDebug.log(
          'registration.failed', {'error_type': error.runtimeType.toString()});
      _registrationFailed('Unable to connect notifications. Retrying…');
    }
  }

  void _registrationFailed(String message) {
    registrationError = message;
    status.value = message;
    debugPrint('[Notifications] $message');
    if (_loggingOut ||
        !AuthSession.instance.signedIn ||
        (_registrationRetry?.isActive ?? false) ||
        _registrationAttempts >= 6) {
      return;
    }
    final seconds = min(120, 5 * (1 << _registrationAttempts++));
    PushDebug.log('registration.retry_scheduled',
        {'delay_seconds': seconds, 'attempt': _registrationAttempts});
    _registrationRetry = Timer(Duration(seconds: seconds), () {
      refreshRegistration().ignore();
    });
  }

  Future<void> _syncRegistration() {
    final result = _binding.then((_) async {
      if (_loggingOut) return;
      final auth = _authToken, fcm = _fcmToken;
      if (_registeredAuth != null &&
          (_registeredAuth != auth || _registeredFcm != fcm)) {
        try {
          await _deviceApi.removePushDevice(_registeredAuth!,
              fcmToken: _registeredFcm!);
        } catch (error) {
          PushDebug.log('registration.old_device_remove_failed',
              {'error_type': error.runtimeType.toString()});
        }
        _registeredAuth = _registeredFcm = null;
      }
      if (auth == null ||
          fcm == null ||
          auth != AuthSession.instance.accessToken) {
        if (auth == null) status.value = 'Sign in to receive notifications.';
        PushDebug.log('registration.skipped', {
          'reason': auth == null
              ? 'no_login_session'
              : fcm == null
                  ? 'no_fcm_token'
                  : 'account_changed'
        });
        return;
      }
      if (_registeredAuth == auth && _registeredFcm == fcm) {
        registrationError = null;
        status.value = 'Ready for push notifications';
        PushDebug.log('registration.already_current',
            {'fcm_fingerprint': PushDebug.fingerprint(fcm)});
        return;
      }
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'macos';
      try {
        final deviceId = await _deviceId();
        PushDebug.log('registration.sending', {
          'user_id': AuthSession.instance.user?.id,
          'employee_id': AuthSession.instance.user?.employeeId,
          'device_id': deviceId,
          'platform': platform,
          'fcm_fingerprint': PushDebug.fingerprint(fcm),
          'project_id': Firebase.app().options.projectId,
        });
        await _deviceApi.registerPushDevice(auth,
            fcmToken: fcm,
            platform: platform,
            appVersion: PackageService.version,
            deviceId: deviceId);
        _registeredAuth = auth;
        _registeredFcm = fcm;
        registrationError = null;
        _registrationRetry?.cancel();
        _registrationAttempts = 0;
        status.value = 'Ready for push notifications';
        debugPrint('[Notifications] $platform device registration accepted.');
        PushDebug.log('registration.accepted', {
          'user_id': AuthSession.instance.user?.id,
          'employee_id': AuthSession.instance.user?.employeeId,
          'device_id': deviceId,
          'fcm_fingerprint': PushDebug.fingerprint(fcm),
        });
      } on ApiException catch (error) {
        PushDebug.log('registration.failed', {
          'error_type': error.runtimeType.toString(),
          'http_status': error.statusCode
        });
        _registrationFailed(error.isUnauthorized
            ? 'Sign in again to connect notifications.'
            : 'Notification registration failed${error.statusCode == null ? '' : ' (HTTP ${error.statusCode})'}. Retrying…');
      } catch (error) {
        PushDebug.log('registration.failed',
            {'error_type': error.runtimeType.toString()});
        _registrationFailed('Unable to register notifications. Retrying…');
      }
    });
    _binding = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('nec_push_device_id_v1');
    if (existing != null) return existing;
    final random = Random.secure();
    final id = List.generate(
            16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    await prefs.setString('nec_push_device_id_v1', id);
    return id;
  }

  Future<void> _unregister(String auth) async {
    PushDebug.log('registration.signing_out',
        {'fcm_fingerprint': PushDebug.fingerprint(_fcmToken)});
    _loggingOut = true;
    _registrationRetry?.cancel();
    _appleRetry?.cancel();
    await _binding;
    final token = _fcmToken;
    if (token != null) {
      try {
        await _deviceApi.removePushDevice(auth, fcmToken: token);
      } catch (_) {}
      // Rotating the token also stops the old account targeting this shared device.
      try {
        await _fcm.deleteToken();
      } catch (_) {}
    }
    _registeredAuth = _registeredFcm = _fcmToken = null;
    status.value = 'Sign in to receive notifications.';
    await _local.cancelAll();
  }

  void _refreshData() {
    NotificationStore.instance.load(filter: 'all', force: true).ignore();
    WorkItemStore.instance.load(force: true).ignore();
    LeadStore.instance.load(force: true).ignore();
    MessageStore.instance.syncRemote().ignore();
    GroupChatStore.instance.syncRemote().ignore();
  }

  void _open(Map<String, dynamic> data) {
    _pendingRoute = NotificationTarget.route(data);
    PushDebug.log('navigation.resolved',
        {'route': _pendingRoute, ...PushDebug.metadata(data)});
    _refreshData();
    final id = data['notification_id']?.toString();
    if (id != null) NotificationStore.instance.markAsRead(id).ignore();
    _flushRoute();
  }

  void _flushRoute() {
    if (_pendingRoute == null || !AuthSession.instance.signedIn) return;
    final route = _pendingRoute!;
    _pendingRoute = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthSession.instance.signedIn) appRouter.push(route);
    });
  }

  Future<void> subscribeToTopic(String topic) => _fcm.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _fcm.unsubscribeFromTopic(topic);

  Future<void> scheduleFollowUpReminder({
    required int id,
    required String leadName,
    required String purpose,
    required DateTime scheduledAt,
    required int reminderMinutes,
    String? method,
    String? leadId,
  }) async {
    final triggerTime = reminderMinutes <= 0
        ? scheduledAt
        : scheduledAt.subtract(Duration(minutes: reminderMinutes));
    final now = DateTime.now();

    final timeStr =
        '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    final title = reminderMinutes <= 0
        ? 'Follow-up Due: $leadName'
        : 'Upcoming Follow-up ($reminderMinutes min reminder)';
    final body = '$purpose with $leadName at $timeStr via ${method ?? 'Call'}.';

    final payload = jsonEncode({
      'type': 'followup',
      'target_id': leadId ?? id.toString(),
      'screen': '/follow-ups',
      'title': title,
      'body': body,
      'notification_id': 'rem_$id',
    });

    final delay = triggerTime.difference(now);

    if (delay.isNegative || delay.inSeconds <= 5) {
      Timer(const Duration(seconds: 2), () async {
        await showCustomNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
        );
      });
      return;
    }

    Timer(delay, () async {
      await showCustomNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    });

    if (!kIsWeb) {
      try {
        final tzTime = tz.TZDateTime.from(triggerTime, tz.local);
        await _local.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzTime,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/ic_notification',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              presentBadge: true,
            ),
            macOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              presentBadge: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } catch (e) {
        debugPrint('[Notifications] Local reminder schedule fallback: $e');
      }
    }
  }

  Future<void> showCustomNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    var cleanBody = body
        .replaceAll(
            RegExp(r'\s*\[\d{1,2}:\d{2}(\s*(?:AM|PM|am|pm))?\]',
                caseSensitive: false),
            '')
        .trim();
    if (cleanBody.toLowerCase() == '[attachment]') {
      cleanBody = 'Sent an attachment';
    } else {
      cleanBody = cleanBody
          .replaceAll(RegExp(r'\[attachment\]', caseSensitive: false),
              'Sent an attachment')
          .trim();
    }
    if (cleanBody.isEmpty) {
      cleanBody = 'Sent an attachment';
    }
    await _local.show(
      id: id,
      title: title,
      body: cleanBody,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> checkAndNotifyProbationEnd({
    required List<Employee> employees,
  }) async {
    final session = AuthSession.instance;
    final currentUserId = session.employeeId;
    final currentBackendId = session.user?.id.toString();
    final isAdmin = session.isAdmin;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final employee in employees) {
      if (!employee.isProbation || employee.probationEndDate == null) continue;
      final end = DateTime.tryParse(employee.probationEndDate!);
      if (end == null) continue;
      final targetDate = DateTime(end.year, end.month, end.day);

      final isSelf = employee.id == currentUserId ||
          (employee.backendId != null && employee.backendId == currentBackendId);
      if (!isAdmin && !isSelf) continue;

      final isDueOrPassed =
          today.isAfter(targetDate) || today.isAtSameMomentAs(targetDate);
      if (isDueOrPassed) {
        final notifyKey =
            'notified_probation_${employee.id}_${employee.probationEndDate}';
        final alreadyNotified = prefs.getBool(notifyKey) ?? false;
        if (!alreadyNotified) {
          final id = (employee.id.hashCode ^ employee.probationEndDate.hashCode)
                  .abs() %
              100000;
          final title = isSelf && !isAdmin
              ? 'Probation Period Completed! 🎉'
              : 'Probation Due: ${employee.name}';
          final body = isSelf && !isAdmin
              ? 'Congratulations! Your probation period ended on ${employee.probationEndDate}. Tap to view your profile and confirm permanent status with HR.'
              : 'Probation period for ${employee.name} ended on ${employee.probationEndDate}. Tap to review and update status to Permanent.';
          final payload = jsonEncode({
            'type': 'employee',
            'screen': '/employee/${employee.id}',
            'target_id': employee.backendId ?? employee.id,
            'title': title,
            'body': body,
          });

          await showCustomNotification(
            id: id,
            title: title,
            body: body,
            payload: payload,
          );
          await prefs.setBool(notifyKey, true);
        }
      }
    }
  }
}
