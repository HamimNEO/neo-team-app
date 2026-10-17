import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_alert_manager.dart';
import 'core/services/package_service.dart';
import 'core/widgets/internet_guard.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/controllers/auth_session.dart';
import 'core/services/staff_access_store.dart';
import 'features/team/data/employee_store.dart';
import 'features/attendance/data/attendance_store.dart';
import 'features/meals/data/meal_store.dart';
import 'features/messages/data/message_store.dart';
import 'features/leads/data/lead_store.dart';
import 'features/settings/data/user_settings_store.dart';
import 'features/tasks/data/work_item_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Graceful fallback if .env is missing
  }

  await PackageService.init();
  await AuthSession.instance.load(verifyInBackground: true);
  await Future.wait([
    StaffAccessStore.instance.restoreLocalPermissions(),
    EmployeeStore.instance.restoreCache(),
    LeadStore.instance.restoreCache(),
    WorkItemStore.instance.restoreCache(),
    MessageStore.instance.load(),
    AttendanceStore.instance.load(),
    MealStore.instance.load(),
    UserSettingsStore.instance.restoreCache(),
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const NecTeamApp(),
    ),
  );
  unawaited(FirebaseService.instance.initialize());
  unawaited(StaffAccessStore.instance.load());
  unawaited(NotificationAlertManager.instance.initialize());
  unawaited(UserSettingsStore.instance.load());
}

class NecTeamApp extends StatelessWidget {
  const NecTeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return ListenableBuilder(
      listenable: UserSettingsStore.instance,
      builder: (context, _) {
        final reduceMotion = UserSettingsStore.instance.reduceMotion;
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          themeAnimationDuration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
          themeAnimationCurve: Curves.easeInOutCubic,
          theme: AppTheme.light(themeProvider.style),
          darkTheme: AppTheme.dark(themeProvider.style),
          routerConfig: appRouter,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
            ),
            child: InternetGuard(
              onFirstConnection: () {
                unawaited(FirebaseService.instance.initialize());
              },
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
