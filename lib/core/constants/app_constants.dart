import '../services/package_service.dart';

class AppConstants {
  static const String appName = 'NEC TEAM';
  static const String appSubtitle = 'BY NEONECY';
  static const String logoAsset =
      'assets/logos/NEC app icon — Rounded — 512 × 512.png';
  static const String largeLogoAsset =
      'assets/logos/NEC app icon — Rounded — 1024 × 1024.png';

  static String get appVersion => PackageService.version;

  static String get appBuildNumber => PackageService.buildNumber;
  static const String plannedBy = 'Nazmul Hasan (CEO)';
  static const String mobileDeveloper = 'MD. ABDUL HAMIM';
  static const String backendDeveloper = 'Yeapas';
  static const String developerName = 'MD. ABDUL HAMIM';
  static const String copyrightYear = '2026';

  static const List<String> interestedPlans = [
    'Online Only',
    'Online + Offline',
    'Complete',
    'Enterprise',
    'Custom',
  ];

  static const List<String> interestedServices = [
    'Hotel Management',
    'Hotel Website',
    'Marketplace',
    'Guest App',
    'Restaurant',
    'Payment',
    'Communication',
    'Custom Solution',
  ];

  static const List<String> contactRoles = [
    'Owner',
    'Managing Director',
    'General Manager',
    'Manager',
    'Front Office Manager',
    'IT / Technology',
    'Other',
  ];

  static const List<String> businessTypes = [
    'Resort',
    'Hotel',
    'Guest House',
    'Restaurant',
    'Other',
  ];

  static const List<String> leadPriorities = [
    'Low',
    'Normal',
    'High',
    'Urgent',
  ];

  static const List<String> leadSources = [
    'Referral',
    'Direct',
    'Website',
    'Cold Call',
    'Exhibition',
  ];

  static const List<String> leadFilterSegments = [
    'All',
    'Mine',
    'New',
    'Follow-up',
  ];

  static const List<String> taskSegments = [
    'To Do',
    'In Progress',
    'Done',
  ];
}
