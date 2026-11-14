import 'package:flutter/material.dart';

/// Centralized responsive design tokens and breakpoint utilities for tablets,
/// iPads, phones, and wide displays across the NEC TEAM app.
class AppResponsive {
  /// Tablet breakpoint threshold (width or shortestSide >= 600)
  static const double kTabletBreakpoint = 600.0;

  /// Wide tablet / landscape iPad breakpoint threshold
  static const double kWideTabletBreakpoint = 900.0;

  /// Desktop breakpoint threshold
  static const double kDesktopBreakpoint = 1200.0;

  /// Max width for single-column detail, settings, and reading views
  static const double kMaxContentWidth = 760.0;

  /// Max width for full-page dashboards (e.g. Home, Leads, Tasks, Team)
  static const double kMaxDashboardWidth = 1080.0;

  /// Max width for forms and modal sheets
  static const double kMaxFormWidth = 620.0;

  /// Max width for auth cards (login, forgot password, OTP)
  static const double kMaxAuthWidth = 460.0;

  /// Max width for floating bottom navigation bar on tablets
  static const double kMaxNavBarWidth = 560.0;

  /// Max width for bottom sheets / modal dialogs
  static const double kMaxSheetWidth = 620.0;

  /// Checks if the current display is a tablet or iPad
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide >= kTabletBreakpoint || size.width >= kTabletBreakpoint;
  }

  /// Checks if the current display is in wide tablet or landscape mode
  static bool isWideTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= kWideTabletBreakpoint;
  }

  /// Checks if the current display is a compact mobile phone
  static bool isPhone(BuildContext context) => !isTablet(context);

  /// Adaptive horizontal content padding
  static double horizontalPadding(BuildContext context) {
    return isTablet(context) ? 24.0 : 16.0;
  }

  /// Returns responsive cross axis count based on screen width
  static int gridColumns(
    BuildContext context, {
    int phone = 1,
    int tablet = 2,
    int wide = 3,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= kWideTabletBreakpoint) return wide;
    if (width >= kTabletBreakpoint) return tablet;
    return phone;
  }
}

/// A container that centers its content and constrains its maximum width on tablets,
/// while filling the available width naturally on phones.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppResponsive.kMaxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Specialized factory for dashboard / overview layouts
  const ResponsiveCenter.dashboard({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
  }) : maxWidth = AppResponsive.kMaxDashboardWidth;

  /// Specialized factory for forms and auth cards
  const ResponsiveCenter.form({
    super.key,
    required this.child,
    double? maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  }) : maxWidth = maxWidth ?? AppResponsive.kMaxFormWidth;

  /// Specialized factory for auth screens
  const ResponsiveCenter.auth({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.center,
  }) : maxWidth = AppResponsive.kMaxAuthWidth;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Align(
      alignment: alignment,
      child: content,
    );
  }
}
