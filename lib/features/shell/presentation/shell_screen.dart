import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/curved_bottom_navigation_bar.dart';
import 'widgets/exit_confirmation_dialog.dart';
import 'widgets/nav_tab_item.dart';
import 'widgets/quick_create_sheet.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/internet_service.dart';
import '../../../core/services/staff_access_store.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  bool _isHandlingBack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DemoSession.instance.addListener(_refreshAccess);
    StaffAccessStore.instance.addListener(_refreshAccess);
  }

  void _refreshAccess() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DemoSession.instance.removeListener(_refreshAccess);
    StaffAccessStore.instance.removeListener(_refreshAccess);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    return _handleBackPress();
  }

  Future<bool> _handleBackPress() async {
    if (!mounted) return false;
    if (!InternetService.instance.isConnected) return true;
    if (_isHandlingBack) return true;
    _isHandlingBack = true;

    try {
      final rootNav = Navigator.of(context, rootNavigator: true);
      if (rootNav.canPop()) {
        await rootNav.maybePop();
        return true;
      }

      if (context.canPop()) {
        context.pop();
        return true;
      }

      final location = GoRouterState.of(context).uri.path;

      if (location != '/home') {
        context.go('/home');
        return true;
      }

      ExitConfirmationDialog.show(context);
      return true;
    } catch (_) {
      return false;
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _isHandlingBack = false;
      });
    }
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (!StaffAccessStore.instance.allows(StaffPermission.leads) &&
        location == '/attendance') {
      return 1;
    }
    if (!StaffAccessStore.instance.allows(StaffPermission.tasks) &&
        location == '/meals') {
      return 3;
    }
    if (location.startsWith('/leads')) return 1;
    if (location.startsWith('/tasks')) return 3;
    if (location.startsWith('/more') ||
        location == '/administration' ||
        location.startsWith('/audit-logs') ||
        location.startsWith('/attendance') ||
        location.startsWith('/meals') ||
        location.startsWith('/system-settings') ||
        location == '/operations-settings' ||
        location == '/follow-up-visit-settings') {
      return 4;
    }
    return 0;
  }

  void _showQuickCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickCreateSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateIndex(context);
    final access = StaffAccessStore.instance;
    final leads = access.allows(StaffPermission.leads);
    final tasks = access.allows(StaffPermission.tasks);
    final attendance = access.allows(StaffPermission.attendance);
    final meals = access.allows(StaffPermission.meals);
    final create = DemoSession.instance.isAdmin ||
        [
          StaffPermission.createLead,
          StaffPermission.createTask,
          StaffPermission.scheduleFollowUp,
          StaffPermission.scheduleVisit,
          StaffPermission.reportIssue
        ].any(access.allows);

    return BackButtonListener(
      onBackButtonPressed: _handleBackPress,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBackPress();
        },
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: widget.child,
          bottomNavigationBar: CurvedBottomNavigationBar(
            selectedIndex: currentIndex,
            items: [
              NavTabItem(
                icon: CupertinoIcons.house,
                activeIcon: CupertinoIcons.house_fill,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              NavTabItem(
                icon: leads
                    ? CupertinoIcons.person_2
                    : attendance
                        ? CupertinoIcons.clock
                        : CupertinoIcons.person,
                activeIcon: leads
                    ? CupertinoIcons.person_2_fill
                    : attendance
                        ? CupertinoIcons.clock_fill
                        : CupertinoIcons.person_fill,
                label: leads
                    ? 'Leads'
                    : attendance
                        ? 'Attendance'
                        : 'Profile',
                active: currentIndex == 1,
                onTap: () {
                  if (leads) {
                    context.go('/leads');
                  } else if (attendance) {
                    context.go('/attendance');
                  } else {
                    context.push('/profile');
                  }
                },
              ),
              NavTabItem(
                icon: create ? CupertinoIcons.add : CupertinoIcons.person,
                activeIcon:
                    create ? CupertinoIcons.add : CupertinoIcons.person_fill,
                label: create ? 'Create' : 'Profile',
                active: false,
                isAction: true,
                onTap: () {
                  if (create) {
                    _showQuickCreate(context);
                  } else {
                    context.push('/profile');
                  }
                },
              ),
              NavTabItem(
                icon: tasks
                    ? CupertinoIcons.checkmark_square
                    : meals
                        ? CupertinoIcons.cart
                        : CupertinoIcons.gear,
                activeIcon: tasks
                    ? CupertinoIcons.checkmark_square_fill
                    : meals
                        ? CupertinoIcons.cart_fill
                        : CupertinoIcons.gear_solid,
                label: tasks
                    ? 'Tasks'
                    : meals
                        ? 'Lunch'
                        : 'Settings',
                active: currentIndex == 3,
                badgeCount: tasks ? 9 : 0,
                onTap: () {
                  if (tasks) {
                    context.go('/tasks');
                  } else if (meals) {
                    context.go('/meals');
                  } else {
                    context.push('/settings');
                  }
                },
              ),
              NavTabItem(
                icon: CupertinoIcons.ellipsis_circle,
                activeIcon: CupertinoIcons.ellipsis_circle_fill,
                label: 'More',
                active: currentIndex == 4,
                onTap: () => context.go('/more'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
