# NEC TEAM — Enterprise CRM Mobile & Multiplatform Application

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--First%20Clean-FF6F00?style=for-the-badge)](#architecture--engineering-design)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Web%20%7C%20Windows%20%7C%20Linux-4CAF50?style=for-the-badge)](#platform-support)
[![Package](https://img.shields.io/badge/Package-com.neonecy.necteam-blueviolet?style=for-the-badge)](#platform-support)

**NEC TEAM** (`neonecy_team_app`) is a flagship, enterprise-grade Customer Relationship Management (CRM) application built exclusively for **NEONECY**. It is engineered to unify business development, hospitality lead qualification, client follow-up tracking, team task delegation, and executive reporting into a seamless, high-performance cross-platform experience.

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture & Engineering Design](#architecture--engineering-design)
3. [Project & Directory Structure](#project--directory-structure)
4. [Role-Based Access Control (RBAC)](#role-based-access-control-rbac)
5. [Core & Enterprise Features](#core--enterprise-features)
   - [Launch & Authentication Experience](#1-launch--authentication-experience)
   - [Shell Navigation & Floating Navbar](#2-shell-navigation--floating-navbar)
   - [Home Executive Dashboard](#3-home-executive-dashboard)
   - [Attendance & Time Tracking Engine](#4-attendance--time-tracking-engine)
   - [Meal & Lunch Management System](#5-meal--lunch-management-system)
   - [Corporate Expense Management (Admin Only)](#6-corporate-expense-management-admin-only)
   - [Employee Directory & Flexible Compensation](#7-employee-directory--flexible-compensation)
   - [Lead Directory & Lifecycle Management](#8-lead-directory--lifecycle-management)
   - [Task Management](#9-task-management)
   - [Follow-Up Automated SMS Engine](#10-follow-up-automated-sms-engine)
   - [Operations Hub (More Tab)](#11-operations-hub-more-tab)
   - [Settings, Theming & Safe Sign Out](#12-settings-theming--safe-sign-out)
6. [Design System & Theme Engine](#design-system--theme-engine)
7. [Tech Stack & Dependencies](#tech-stack--dependencies)
8. [Getting Started & Development](#getting-started--development)
9. [Platform Support](#platform-support)
10. [Lead Developer & Maintainer](#-lead-developer--maintainer)

---

## Project Overview

NEONECY drives cutting-edge hospitality software and enterprise management platforms. The **NEC TEAM** application serves as the core operational cockpit for NEONECY's sales directors, field executives, and account managers. 

### Key Business Goals
- **End-to-End Pipeline Visibility**: Track potential clients from cold outreach and initial inquiry to contract signing and deployment.
- **Actionable Daily Agendas**: Surface urgent follow-ups, overdue client touchpoints, and scheduled on-site property visits before the workday starts.
- **Attendance & Work Session Intelligence**: Geofenced, office, and remote check-ins with shift and overtime tracking.
- **Company Resource Management**: Subsidized meal plans and corporate financial expense governance.
- **Flexible Compensation Models**: Automatic salary deductions for customized meal contributions and annual rotational reserve savings.
- **Cross-Team Accountability**: Coordinate deliverables between sales, product, and client onboarding teams through synchronized tasks.

---

## Architecture & Engineering Design

The project is structured according to **Feature-First (Modular) Clean Architecture**. This paradigm prioritizes domain cohesion, high reusability, testability, and zero code coupling between distinct business verticals.

```
                          ┌────────────────────────┐
                          │   main.dart & Shell    │
                          └───────────┬────────────┘
                                      │
            ┌─────────────────────────┼─────────────────────────┐
            ▼                         ▼                         ▼
   ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
   │  features/home  │       │ features/leads  │       │ features/tasks  │
   │ ┌─────────────┐ │       │ ┌─────────────┐ │       │ ┌─────────────┐ │
   │ │Presentation │ │       │ │Presentation │ │       │ │Presentation │ │
   │ │  & Widgets  │ │       │ │  & Widgets  │ │       │ │  & Widgets  │ │
   │ └─────────────┘ │       │ ├─────────────┤ │       │ ├─────────────┤ │
   │                 │       │ │Domain Models│ │       │ │Domain Models│ │
   │                 │       │ ├─────────────┤ │       │ ├─────────────┤ │
   │                 │       │ │ Data Layer  │ │       │ │ Data Layer  │ │
   │ └─────────────┘ │       │ └─────────────┘ │       │ └─────────────┘ │
   └────────┬────────┘       └────────┬────────┘       └────────┬────────┘
            │                         │                         │
            └─────────────────────────┼─────────────────────────┘
                                      ▼
                        ┌───────────────────────────┐
                        │        lib/core/          │
                        │  - Theme & Design Tokens  │
                        │  - Atomic UI Components   │
                        │  - Central GoRouter       │
                        │  - Constants & Enums      │
                        └───────────────────────────┘
```

### Architectural Principles

1. **Feature Encapsulation (Vertical Slices)**:
   Each feature directory (`home`, `leads`, `tasks`, `team`, `auth`, `settings`, `more`) contains its own models, repositories, presentation screens, and dedicated sub-widgets. Changes within one feature never cause ripple regressions in others.

2. **Minimalist Screen Composition**:
   Screen files are kept lean, readable, and declarative. Instead of massive 800+ line widget trees, screens serve as layout orchestrators that compose focused, single-responsibility sub-widgets from their local `presentation/widgets/` directories.

3. **Core Layer Subsystem**:
   Shared components live in `lib/core/`:
   - `core/theme/`: Comprehensive design tokens (`AppColors`, `AppTheme`) and dynamic theme state (`ThemeProvider`).
   - `core/widgets/`: Enterprise-grade atomic components (`NecButton`, `NecBadge`, `NecAvatar`, `SectionHeader`, `SettingsRow`).
   - `core/router/`: Declarative URL-friendly routing driven by `GoRouter`.
   - `core/constants/`: Single source of truth for app metadata, CRM categories, and status enumerations.

4. **Dynamic Theme Engine with Local Persistence**:
   The app defaults to a modern, crisp **Light Theme**, with full support for **Dark** and **System** modes. The theme state is held by `ThemeProvider` and automatically saved to device disk using `SharedPreferences` (`nec_theme_mode`), ensuring user preferences survive cold restarts.

5. **Flutter 3.44+ Material Canvas Conformance**:
   All interactive cards, list tiles, and touch targets are wrapped within explicit `Material` canvas widgets (`clipBehavior: Clip.antiAlias`, `color: Colors.transparent`) rather than bare decorated containers. This guarantees full compatibility with Flutter's latest rendering pipeline and ensures ink splashes and ripples are always visible.

6. **Native Production Packaging**:
   Unified reverse-DNS identifier `com.neonecy.necteam` across all target platforms with customized native app icons and an instant white native splash screen matching the in-app brand identity.

---

## Project & Directory Structure

```
neonecy_team_app/
├── android/                                # Android native project (com.neonecy.necteam)
├── ios/                                    # iOS native project (Runner / LaunchScreen)
├── macos/                                  # macOS desktop runner
├── web/                                    # Web platform configuration
├── windows/                                # Windows desktop runner
├── linux/                                  # Linux desktop runner
├── assets/
│   ├── logos/
│   │   └── nec-app-logo.png                # Official 1024x1024 high-res master app icon
│   └── others/
│       └── login-banner.png                # High-res auth hero banner graphic
│
└── lib/
    ├── main.dart                           # Entrypoint, MultiProvider & theme listener
    │
    ├── core/                               # Core shared foundation
    │   ├── constants/
    │   │   └── app_constants.dart          # CRM enums, package names, labels & dropdown data
    │   ├── router/
    │   │   └── app_router.dart             # GoRouter setup with ShellRoute bottom navigation
    │   ├── theme/
    │   │   ├── app_colors.dart             # Raw hex color definitions & NecColors theme extension
    │   │   ├── app_theme.dart              # Light & Dark ThemeData definitions
    │   │   └── theme_provider.dart         # ChangeNotifier managing & persisting ThemeMode
    │   └── widgets/                        # Reusable atomic UI building blocks
    │       ├── nec_avatar.dart             # Circular avatar with initials fallback & online dot
    │       ├── nec_badge.dart              # Priority & status tag badge with custom colors
    │       ├── nec_button.dart             # Standardized primary, secondary & text buttons
    │       ├── section_header.dart         # Consistent title & subtitle section divider
    │       └── settings_row.dart           # Touch-friendly settings tile with chevron/toggle
    │
    └── features/                           # Domain feature modules
        ├── splash/presentation/            # Animated splash screen with brand entrance
        ├── auth/presentation/              # Hero banner login sheet & credential validation
        ├── shell/presentation/             # Responsive floating shell & back interceptor
        ├── home/presentation/              # Role-aware dashboard & performance metrics
        │
        ├── attendance/                     # Workforce attendance & time tracking
        │   ├── domain/models/              # Attendance session and record models
        │   ├── data/mock_attendance.dart   # Attendance data store & daily records
        │   └── presentation/
        │       ├── attendance_screen.dart        # Self-service punch & shift overview
        │       ├── attendance_admin_screen.dart  # Admin daily workforce reporting hub
        │       ├── attendance_settings_screen.dart # Shift & geofence parameters
        │       └── widgets/
        │           ├── attendance_home_card.dart # Live dashboard attendance card
        │           ├── attendance_month_view.dart# Monthly attendance calendar
        │           └── attendance_requests.dart  # Leave & manual punch requests
        │
        ├── meals/                          # Staff meal & lunch management
        │   ├── domain/models/meal_record.dart # Meal entitlement and pricing models
        │   ├── data/meal_store.dart        # Real-time meal counter & status store
        │   └── presentation/
        │       ├── meal_screen.dart        # Dual-mode staff & admin lunch tracker
        │       └── widgets/lunch_entry.dart# Meal indicator tile
        │
        ├── expenses/                       # Admin corporate expense management
        │   ├── domain/models/expense.dart  # Expense entity, categories & payment enums
        │   ├── data/expense_store.dart     # Corporate expense repository & metrics
        │   └── presentation/
        │       ├── expenses_screen.dart    # Search, category filters & monthly summary
        │       ├── expense_details_screen.dart # Full receipt & vendor breakdown
        │       └── widgets/add_expense_sheet.dart # 80% viewport modal creation sheet
        │
        ├── team/                           # Company directory & HR onboarding
        │   ├── domain/models/employee.dart # Team member entity model
        │   ├── data/employee_store.dart    # Personnel dataset & active status store
        │   └── presentation/
        │       ├── team_screen.dart        # Searchable directory & department grouping
        │       ├── add_employee_screen.dart# Multi-step employee creation wizard
        │       ├── employee_profile_screen.dart # Profile dossier & benefits breakdown
        │       └── widgets/
        │           ├── employee_salary_step.dart # Meal & rotational reserve setup
        │           ├── employee_personal_step.dart
        │           └── employee_job_step.dart
        │
        ├── leads/                          # Hotel & enterprise lead management
        │   ├── domain/models/lead.dart     # Lead model, packages & qualification status
        │   ├── data/mock_leads.dart        # Hospitality lead roster
        │   └── presentation/               # Lead list, lead dossier & intake forms
        │
        ├── tasks/                          # Coordinated task management
        │   ├── domain/models/task.dart     # Task model, assignees & priorities
        │   ├── data/mock_tasks.dart        # Task roster tied to CRM leads
        │   └── presentation/               # Kanban board & task inspection
        │
        ├── settings/presentation/          # Auto-SMS triggers, options & appearance
        └── more/presentation/              # Operations hub (Follow-ups, Visits, Issues)
```

---

## Role-Based Access Control (RBAC)

**NEC TEAM** incorporates an enterprise Role-Based Access Control system to enforce strict separation of duties between executive management and frontline staff:

- **Company Administrator (`admin@neonecy.com`)**:
  - Full visibility over corporate finances, monthly spend, and pending expenses.
  - Creation, editing, and deletion of corporate expenses.
  - Organization-wide workforce attendance reporting with department and status filtering.
  - Authority to add new employees and configure custom compensation policies (base salary, meal deduction percentages, and rotational reserve savings).
  - Authority to update today's and upcoming staff lunch rosters.
  - Unrestricted delegation and reassignment capabilities across leads, tasks, and site visits.

- **Standard Staff Member (Any non-admin credentials)**:
  - Personalized, focused dashboard tailored to individual tasks, assigned leads, and daily follow-ups.
  - Self-service attendance logging (Check-in, Check-out, Break, Overtime monitoring).
  - Personal lunch status verification and monthly deduction tracking.
  - View-only access to the public company directory.
  - Strict security lockouts preventing access to sensitive corporate expenses, employee compensation settings, or company-wide attendance audits.

---

## Core & Enterprise Features

### 1. Launch & Authentication Experience
- **Seamless Branded Splash**: Features a crisp white background (`#FFFFFF`) with the centered `nec-app-logo.png`. Employs smooth scale and opacity animations, transitioning directly to the login flow without screen flashes or black borders.
- **Login Screen with Hero Banner**:
  - Top half displays `assets/others/login-banner.png` overlaid with the official logo, app title (**NEC TEAM**), and tagline (**NEONECY ENTERPRISE CRM**).
  - Curved bottom sheet with work email validation, visibility-toggle password field, and role-aware authentication routing.

### 2. Shell Navigation & Floating Navbar
- **Floating Curved Shell Bar**:
  - Consistent design across Light and Dark modes with an arched center dome, crescent stroke highlight rim, and glowing center action button (`#6355F6`).
  - Compact dimensions (**`52px`** height, **`17px`** crisp outline icons, elevated bottom clearance) floating cleanly above system bars.
- **Multi-Layered Native Back-Button Handling**:
  - Intercepts phone back button via `BackButtonListener`.
  - Automatically dismisses active bottom sheets on first press.
  - Smoothly routes secondary tabs (**Leads**, **Tasks**, **More**) back to the **Home** tab (`/home`).
  - Displays an adaptive **Exit Confirmation Dialog** (`ExitConfirmationDialog`) when triggered from the root Home tab.

### 3. Home Executive Dashboard
- **Role-Aware Layout**: Surfaces high-priority KPIs for administrators and personal operational workflows for staff.
- **Pipeline Metric Grid**:
  - **New Leads**: Count of recently captured leads waiting for qualification.
  - **My Leads**: Active leads assigned directly to the current user.
  - **Follow-ups Due**: Urgent reminders for today's client touchpoints.
  - **Visits Today**: Scheduled on-site hotel/resort inspections.
- **Shimmer Skeleton Loading**: Custom skeleton placeholders reflecting the active user's role during startup and refresh cycles.

### 4. Attendance & Time Tracking Engine
- **Staff Home Attendance Card (`AttendanceHomeCard`)**:
  - Prominent real-time dashboard widget displaying today's shift timings, check-in status, and overtime accrual.
  - Visual status pill indicators with Cupertino icons.
  - Quick-action buttons to Punch In, Start Break, End Break, or Punch Out.
- **Admin Workforce Attendance Hub (`AttendanceAdminScreen`)**:
  - Comprehensive daily roster of all company employees.
  - Multi-status filter tabs: **All**, **Present**, **Late**, **Absent**, and **On Leave**.
  - Dynamic department selector and calendar date navigation.
  - Search by employee name or staff ID.
- **Geofenced & Remote Modes**: Support for standard office geofence verification and approved remote work arrangements.

### 5. Meal & Lunch Management System
- **Company Lunch Entitlement**:
  - Unified system tracking company-provided lunches and meals for active staff.
  - Daily headcount card showing total meals counted, active staff, and automatic exclusions for approved leave or weekly off days.
- **Dual-Perspective Views**:
  - **Staff View**: Immediate confirmation of today's meal status and accumulated monthly lunch contributions.
  - **Admin View**: Interactive company-wide lunch roster with real-time toggle switches for today and future scheduled dates (past records protected as read-only).
- **Flexible Payroll Deduction Integration**:
  - Supports 100% company-paid meals (Free), fixed company subsidies, or percentage-based employee sharing (e.g. 50%, 60%).
  - Live calculation showing the exact meal contribution cut from monthly salary.

### 6. Corporate Expense Management (Admin Only)
- **Executive Financial Cockpit (`ExpensesScreen`)**:
  - Restricted strictly to company owners and administrators.
  - Overview card presenting **This Month Spend**, **Paid Amount**, and **Pending/Due** balances with instant record counters.
- **High-Density Search & Filter**:
  - Vertically centered search bar with left-aligned prefix icon and instant text clear.
  - Category filter pills: *Software*, *Travel*, *Office Supplies*, *Marketing*, *Meals*, *Utilities*, *Hardware*, *Legal*, and *Miscellaneous*.
  - Status filter chips: *All*, *Paid*, *Pending*, and *Overdue* (without obstructive checkmarks).
- **High-Fidelity Creation Sheet (`AddExpenseSheet`)**:
  - 80% viewport height modal sheet with a persistent drag handle and sticky header.
  - Choice chips for categories, date pickers, amount inputs with currency formatting, vendor fields, and payment method selection (Bank Transfer, Credit Card, Cash, Mobile Banking).
  - Optional receipt attachment toggle.

### 7. Employee Directory & Flexible Compensation
- **Searchable Personnel Directory (`TeamScreen`)**:
  - Fast search by staff name, ID, or job designation with department groupings.
  - Detailed employee dossier (`EmployeeProfileScreen`).
- **Multi-Step Onboarding Wizard (`AddEmployeeScreen`)**:
  - Structured wizard dividing onboarding into **Personal Info**, **Job Details**, **Emergency Contacts**, and **Compensation**.
- **Configurable Salary & Deduction Flags**:
  - **Meal Allowance & Deduction**: Admin enters total company meal cost and selects the employee share percentage. The system automatically computes and displays the exact salary deduction.
  - **Rotational Reserve Fund**: Optional flag-based savings policy where a fixed monthly amount is withheld from salary into a company reserve, eligible for full withdrawal by the employee in the final month of the year.
  - Both benefit flags are cleanly presented in the employee's personal profile view.

### 8. Lead Directory & Lifecycle Management
- **Segmented Filter Bar**: Instant switching between **All**, **Mine**, **New**, and **Follow-up** tabs.
- **Live Search**: Rapid client filtering by hotel name, business entity, or contact person.
- **Comprehensive Lead Dossier**:
  - Sliver Hero Header with hotel classification and priority tags.
  - Sticky Tab Bar: **Overview** (HMS & room specs), **Follow-ups**, **Tasks**, and **Activity Audit**.
- **Lead Onboarding Form**: Fast multi-section intake for property specifications, contact persons, and priority tiers.

### 9. Task Management
- **Segmented Workflow**: Switch easily between **To Do**, **In Progress**, and **Done**.
- **Task Cards**: Display task title, priority tag (**Urgent**, **High**, **Normal**, **Low**), due date, assignee avatar, and associated CRM lead name.
- **Task Detail Inspection**: Inspect requirements, change completion status, and reassign team members.

### 10. Follow-Up Automated SMS Engine
- **Automated Client SMS Reminder System**: Eliminates missed follow-ups by preparing and triggering automated SMS notifications when follow-ups approach.
- **Auto-SMS Configuration (`/auto-sms-settings`)**:
  - Master enable/pause toggle.
  - Timings (*15 min before*, *30 min before*, *1 hour before*, *On scheduled time*).
  - Recipient selection (*Client*, *Assigned Representative*, or *Both*).
  - Dynamic template editor with live tokens (`{client_name}`, `{date}`, `{time}`, `{purpose}`, `{rep_name}`).
  - Simulated dispatch tester with mobile preview.

### 11. Operations Hub (More Tab)
- Sub-screens for comprehensive operational oversight:
  - **Activity Stream**: Chronological audit feed of recent CRM actions across all team members.
  - **Follow-ups Tracker**: Central calendar view of all scheduled client meetings, calls, and auto-SMS statuses.
  - **Issues Log**: Dedicated ticketing list for client-reported software issues with status tags.
  - **Site Visits**: Route map and agenda for field representatives visiting properties with Google Maps deep-linking.
  - **Notifications**: Notification inbox for mentions, task assignments, and overdue warnings.
  - **Global Search**: Search bar querying across leads, contacts, tasks, and employees simultaneously.

### 12. Settings, Theming & Safe Sign Out
- **Appearance & Theme Selector**: Switch between System Default, Light Theme, or Dark Theme with instant cross-screen transitions and local disk persistence.
- **Profile Screen**: Displays full executive credentials: Name, Employee ID, Corporate Email, Department, and compensation flags.
- **Guarded Sign Out**: Confirmation modal preventing accidental session termination, navigating cleanly back to `/login`.

---

## Design System & Theme Engine

NEONECY's design system is crafted for high-density enterprise productivity while delivering a modern, premium aesthetic.

### Color Tokens

| Token | Light Mode | Dark Mode | Usage |
| :--- | :--- | :--- | :--- |
| **Primary** | `#007AFF` | `#0A84FF` | Primary actions, active tabs, brand accents |
| **Primary Container** | `#E5F2FF` | `#0B2545` | Selected card highlights, subtle badges |
| **Scaffold Background** | `#F8F9FA` | `#000000` | Main window canvas |
| **Surface Card** | `#FFFFFF` | `#1C1C1E` | Card backgrounds, list tiles, bottom sheets |
| **Surface Secondary** | `#F2F2F7` | `#2C2C2E` | Inputs, chip backgrounds, search fields |
| **Text Primary** | `#1C1C1E` | `#FFFFFF` | Headings, primary labels |
| **Text Secondary** | `#8E8E93` | `#8E8E93` | Metadata, subtitles, timestamps |
| **Success** | `#34C759` | `#30D158` | Won leads, completed tasks |
| **Warning** | `#FF9500` | `#FF9F0A` | Pending actions, medium priority |
| **Error / Urgent** | `#FF3B30` | `#FF453A` | Overdue alerts, urgent tasks, sign out |

### Typography
The application uses **Google Fonts Inter** across all platforms, offering exceptional legibility for dense data tables, KPI counters, and operational reports.

---

## Tech Stack & Dependencies

| Package | Version | Purpose |
| :--- | :--- | :--- |
| **`flutter`** | SDK `>=3.0.0 <4.0.0` | High-performance multi-platform UI framework |
| **`go_router`** | `^14.8.1` | Declarative routing, deep-linking, and `ShellRoute` nested navigation |
| **`provider`** | `^6.1.2` | Reactive state management for theme preferences |
| **`google_fonts`** | `^6.2.1` | Dynamic typography system (Inter) |
| **`shared_preferences`**| `^2.3.5` | Persistent local key-value store for user configurations |
| **`intl`** | `^0.20.2` | Enterprise date formatting and currency presentation |
| **`cupertino_icons`** | `^1.0.8` | High-fidelity platform icons |

---

## Getting Started & Development

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.0.0 <4.0.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>=3.0.0 <4.0.0`)
- Xcode (for iOS and macOS development)
- Android Studio / Android SDK (for Android development)

### 1. Clone & Setup
```bash
git clone https://github.com/neonecy/neonecy_team_app.git
cd neonecy_team_app
flutter pub get
```

### 2. Run the Application

```bash
# Run on currently connected device or default simulator:
flutter run

# Run on specific target platforms:
flutter run -d chrome       # Google Chrome (Web)
flutter run -d macos        # macOS Desktop
flutter run -d ios          # iOS Simulator or Connected iPhone
flutter run -d android      # Android Emulator or Connected Device
flutter run -d windows      # Windows Desktop
flutter run -d linux        # Linux Desktop
```

### 3. Quality & Static Analysis

```bash
# Run code analysis (0 errors, 0 warnings standard)
flutter analyze

# Execute test suite
flutter test
```

---

## Platform Support

| Platform | Support Status | Package / Bundle Identifier | Native Display Title |
| :--- | :---: | :--- | :--- |
| **iOS** | Supported | `com.neonecy.necteam` | **NEC TEAM** |
| **Android** | Supported | `com.neonecy.necteam` | **NEC TEAM** |
| **macOS** | Supported | `com.neonecy.necteam` | **NEC TEAM** |
| **Web** | Supported | `neonecy_team_app` | **NEC TEAM** |
| **Windows** | Supported | `neonecy_team_app` | **NEC TEAM** |
| **Linux** | Supported | `neonecy_team_app` | **NEC TEAM** |

---

## 👨‍💻 Lead Developer & Maintainer

Developed and maintained by:
**MD. ABDUL HAMIM LEON**  
Lead Flutter Developer — NEONECY  
🌐 Portfolio: [https://thedevhamim.vercel.app/](https://thedevhamim.vercel.app/)

Maintained with ❤️ by **NEONECY** and the **BinGi Engineering Team**.
