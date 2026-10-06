# neonecy_team_app (NEONECY TEAM APP — Flutter App)

Cross-platform Flutter application for NEC TEAM CRM by NEONECY.

## Architecture: Feature-First Modular Clean Architecture

The codebase is organized into **Core** infrastructure and **Feature** modules. Each feature contains its own domain models, data sources, presentation screens, and dedicated sub-widgets.

```
lib/
├── core/
│   ├── constants/             # App-wide constants and enumerations
│   ├── theme/                 # AppTheme, AppColors, and ThemeProvider
│   ├── router/                # Central GoRouter configuration
│   └── widgets/               # Reusable atomic UI components (NecButton, NecBadge, etc.)
│
├── features/
│   ├── splash/presentation/   # Splash screen with logo animation
│   ├── auth/presentation/     # LoginScreen and auth-specific widgets
│   ├── shell/presentation/    # App shell, responsive bottom navigation & quick create
│   ├── home/presentation/     # HomeScreen, greeting bar, metric cards & lead lists
│   ├── leads/                 # Leads module (models, mock data, screens & widgets)
│   ├── tasks/                 # Tasks module (models, mock data, screens & widgets)
│   ├── team/                  # Team module (models, mock data, screens & widgets)
│   ├── settings/presentation/ # Settings, Appearance & Profile
│   └── more/presentation/     # More tab and operations sub-screens
│
└── main.dart                  # Application entrypoint
```

## Development & Running

- Install dependencies: `flutter pub get`
- Run application: `flutter run`
- Run on specific platform:
  - macOS: `flutter run -d macos`
  - Web: `flutter run -d chrome`
  - iOS Simulator: `flutter run -d ios`
  - Android: `flutter run -d android`
  - Windows: `flutter run -d windows`
  - Linux: `flutter run -d linux`
- Run tests: `flutter test`
- Run analysis: `flutter analyze`
