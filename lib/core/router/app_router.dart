import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shell_safe_router.dart';
import 'app_navigation.dart';
import '../../features/messages/presentation/messages_screen.dart';
import '../../features/messages/presentation/conversation_screen.dart';
import '../services/demo_session.dart';
import '../../features/team/data/employee_store.dart';
import '../../features/settings/presentation/change_password_screen.dart';
import '../../features/settings/presentation/employee_password_screen.dart';
import '../services/staff_access_store.dart';
import '../../features/settings/presentation/staff_access_screen.dart';

import '../../features/audit/presentation/audit_detail_screen.dart';
import '../../features/audit/presentation/audit_logs_screen.dart';
import '../../features/meals/presentation/meal_screen.dart';
import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/attendance/presentation/attendance_admin_screen.dart';
import '../../features/attendance/presentation/attendance_settings_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/password_reset_success_screen.dart';
import '../../features/auth/presentation/set_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/leads/presentation/add_lead_screen.dart';
import '../../features/leads/presentation/lead_details_screen.dart';
import '../../features/leads/presentation/leads_screen.dart';
import '../../features/more/presentation/activity_screen.dart';
import '../../features/more/presentation/follow_up_details_screen.dart';
import '../../features/more/presentation/follow_ups_screen.dart';
import '../../features/more/presentation/issues_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/more/presentation/notifications_screen.dart';
import '../../features/more/presentation/search_screen.dart';
import '../../features/more/presentation/visit_details_screen.dart';
import '../../features/more/presentation/visits_screen.dart';
import '../../features/more/presentation/widgets/report_issue_sheet.dart';
import '../../features/settings/presentation/about_screen.dart';
import '../../features/settings/presentation/account_security_screen.dart';
import '../../features/settings/presentation/administration_screen.dart';
import '../../features/settings/presentation/app_permissions_screen.dart';
import '../../features/settings/presentation/appearance_screen.dart';
import '../../features/settings/presentation/auto_sms_settings_screen.dart';
import '../../features/settings/presentation/follow_up_visit_settings_screen.dart';
import '../../features/settings/presentation/business_types_screen.dart';
import '../../features/settings/presentation/custom_fields_screen.dart';
import '../../features/settings/presentation/lead_priorities_screen.dart';
import '../../features/settings/presentation/lead_settings_screen.dart';
import '../../features/settings/presentation/lead_sources_screen.dart';
import '../../features/settings/presentation/lead_statuses_screen.dart';
import '../../features/settings/presentation/lost_reasons_screen.dart';
import '../../features/settings/presentation/module_manager_screen.dart';
import '../../features/settings/presentation/new_role_screen.dart';
import '../../features/settings/presentation/notification_preferences_screen.dart';
import '../../features/settings/presentation/operations_settings_screen.dart';
import '../../features/settings/presentation/task_settings_screen.dart';
import '../../features/settings/presentation/issue_settings_screen.dart';
import '../../features/settings/presentation/organization_information_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/settings/presentation/edit_profile_screen.dart';
import '../../features/settings/presentation/role_details_screen.dart';
import '../../features/settings/presentation/role_permissions_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/system_settings_screen.dart';
import '../../features/shell/presentation/shell_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/tasks/presentation/create_task_screen.dart';
import '../../features/tasks/presentation/task_details_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/team/presentation/add_employee_screen.dart';
import '../../features/team/presentation/department_details_screen.dart';
import '../../features/team/presentation/departments_screen.dart';
import '../../features/team/presentation/employee_profile_screen.dart';
import '../../features/team/presentation/team_details_screen.dart';
import '../../features/team/presentation/team_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/expenses/presentation/expense_details_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

Page<dynamic> _buildPage(GoRouterState state, Widget child) {
  return MaterialPage<dynamic>(
    key: state.pageKey,
    child: child,
  );
}

String? _redirectLocation(String location) {
  final uri = Uri.parse(location);
  final path = uri.path;
  if (path == '/stacked') {
    final destination = uri.queryParameters['screen'];
    if (destination == null || _stackedScreen(Uri.parse(destination)) == null) {
      return '/access-denied';
    }
    final redirect = _redirectLocation(destination);
    if (redirect == null) return null;
    return _stackedScreen(Uri.parse(redirect)) == null
        ? redirect
        : Uri(path: '/stacked', queryParameters: {'screen': redirect})
            .toString();
  }
  if (path == '/') return null;
  const publicPaths = {
    '/login',
    '/forgot-password',
    '/otp-verification',
    '/set-password',
    '/password-reset-success',
  };
  if (publicPaths.contains(path)) {
    return path == '/login' && DemoSession.instance.signedIn ? '/home' : null;
  }
  if (!DemoSession.instance.signedIn) return '/login';
  if (path.startsWith('/employee/') &&
      path.endsWith('/password') &&
      !DemoSession.instance.isAdmin) {
    return '/access-denied';
  }
  if (path == '/employee/${DemoSession.instance.employeeId}') return '/profile';
  if (DemoSession.instance.isAdmin) {
    if (path == '/attendance') return '/attendance/admin';
    if (path == '/meals') return '/meals/admin';
    if (path.startsWith('/attendance/employee/') &&
        !EmployeeStore.instance
            .isStaffEmployee(Uri.parse(location).pathSegments.last)) {
      return '/attendance/admin';
    }
  }
  return StaffAccessStore.instance.canOpen(path) ? null : '/access-denied';
}

/// Root presentations reuse the same screens while retaining the page that
/// opened them. The existing shell remains mounted underneath exactly once.
Widget? _stackedScreen(Uri destination) {
  final path = destination.path;
  if (path.startsWith('/attendance/employee/')) {
    return AttendanceScreen(
        employeeId: destination.pathSegments.last,
        initialMonth:
            DateTime.tryParse(destination.queryParameters['month'] ?? ''));
  }
  if (path.startsWith('/audit-logs/')) {
    return AuditDetailScreen(auditId: destination.pathSegments.last);
  }
  return switch (path) {
    '/meals' => const MealScreen(),
    '/meals/admin' => const MealScreen(administrator: true),
    '/attendance' => const AttendanceScreen(),
    '/attendance/admin' => const AttendanceAdminScreen(),
    '/attendance/settings' => const AttendanceSettingsScreen(),
    '/administration' => const AdministrationScreen(),
    '/operations-settings' => const OperationsSettingsScreen(),
    '/follow-up-visit-settings' => const FollowUpVisitSettingsScreen(),
    '/task-settings' => const TaskSettingsScreen(),
    '/issue-settings' => const IssueSettingsScreen(),
    '/audit-logs' => const AuditLogsScreen(),
    '/system-settings' => const SystemSettingsScreen(),
    '/system-settings/organization' => const OrganizationInformationScreen(),
    '/leads' =>
      const _StackedTabScreen(title: 'Manage Leads', child: LeadsScreen()),
    '/tasks' =>
      const _StackedTabScreen(title: 'Manage Tasks', child: TasksScreen()),
    '/home' => const _StackedTabScreen(title: 'Home', child: HomeScreen()),
    '/more' => const _StackedTabScreen(title: 'More', child: MoreScreen()),
    _ => null,
  };
}

class _StackedTabScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const _StackedTabScreen({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            leading: BackButton(onPressed: () => context.popAppRoute())),
        body: child,
      );
}

final GoRouter appRouter = ShellSafeRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable:
      Listenable.merge([DemoSession.instance, StaffAccessStore.instance]),
  redirect: (context, state) => _redirectLocation(state.uri.toString()),
  resolveLocation: (location) => _redirectLocation(location) ?? location,
  routes: [
    GoRoute(
      path: '/employee/:id/password',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(state,
          EmployeePasswordScreen(employeeId: state.pathParameters['id'] ?? '')),
    ),
    GoRoute(
      path: '/stacked',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
          state,
          _stackedScreen(
                  Uri.parse(state.uri.queryParameters['screen'] ?? '')) ??
              const SizedBox.shrink()),
    ),
    GoRoute(
      path: '/change-password',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const ChangePasswordScreen()),
    ),
    GoRoute(
      path: '/messages',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const MessagesScreen()),
    ),
    GoRoute(
      path: '/messages/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        ConversationScreen(employeeId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
        path: '/staff-access',
        pageBuilder: (context, state) =>
            _buildPage(state, const StaffAccessScreen(editable: true))),
    GoRoute(
        path: '/my-access',
        pageBuilder: (context, state) =>
            _buildPage(state, const StaffAccessScreen())),
    GoRoute(
        path: '/access-denied',
        pageBuilder: (context, state) => _buildPage(
            state,
            Scaffold(
                appBar: AppBar(title: const Text('Access Unavailable')),
                body: Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lock_outline, size: 44),
                          const SizedBox(height: 16),
                          const Text(
                              'Your role does not have access to this screen. Contact your administrator.',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          TextButton(
                              onPressed: () => context.go('/home'),
                              child: const Text('Back to Home')),
                        ])))))),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _buildPage(state, const SplashScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPage(state, const LoginScreen()),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const ForgotPasswordScreen()),
    ),
    GoRoute(
      path: '/otp-verification',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return _buildPage(state, OtpVerificationScreen(email: email));
      },
    ),
    GoRoute(
      path: '/set-password',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const SetPasswordScreen()),
    ),
    GoRoute(
      path: '/password-reset-success',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const PasswordResetSuccessScreen()),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/meals',
          pageBuilder: (context, state) =>
              _buildPage(state, const MealScreen()),
        ),
        GoRoute(
          path: '/meals/admin',
          pageBuilder: (context, state) =>
              _buildPage(state, const MealScreen(administrator: true)),
        ),
        GoRoute(
          path: '/attendance',
          pageBuilder: (context, state) =>
              _buildPage(state, const AttendanceScreen()),
        ),
        GoRoute(
          path: '/attendance/admin',
          pageBuilder: (context, state) =>
              _buildPage(state, const AttendanceAdminScreen()),
        ),
        GoRoute(
          path: '/attendance/settings',
          pageBuilder: (context, state) =>
              _buildPage(state, const AttendanceSettingsScreen()),
        ),
        GoRoute(
          path: '/attendance/employee/:id',
          pageBuilder: (context, state) => _buildPage(
              state,
              AttendanceScreen(
                  employeeId: state.pathParameters['id'] ?? '',
                  initialMonth: DateTime.tryParse(
                      state.uri.queryParameters['month'] ?? ''))),
        ),
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/leads',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const LeadsScreen(),
          ),
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const TasksScreen(),
          ),
        ),
        GoRoute(
          path: '/more',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const MoreScreen(),
          ),
        ),
        GoRoute(
          path: '/administration',
          pageBuilder: (context, state) =>
              _buildPage(state, const AdministrationScreen()),
        ),
        GoRoute(
          path: '/operations-settings',
          pageBuilder: (context, state) =>
              _buildPage(state, const OperationsSettingsScreen()),
        ),
        GoRoute(
          path: '/follow-up-visit-settings',
          pageBuilder: (context, state) =>
              _buildPage(state, const FollowUpVisitSettingsScreen()),
        ),
        GoRoute(
          path: '/task-settings',
          pageBuilder: (context, state) =>
              _buildPage(state, const TaskSettingsScreen()),
        ),
        GoRoute(
          path: '/issue-settings',
          pageBuilder: (context, state) =>
              _buildPage(state, const IssueSettingsScreen()),
        ),
        GoRoute(
          path: '/audit-logs',
          pageBuilder: (context, state) =>
              _buildPage(state, const AuditLogsScreen()),
          routes: [
            GoRoute(
              path: ':id',
              pageBuilder: (context, state) => _buildPage(
                state,
                AuditDetailScreen(auditId: state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/system-settings',
          pageBuilder: (context, state) =>
              _buildPage(state, const SystemSettingsScreen()),
          routes: [
            GoRoute(
              path: 'organization',
              pageBuilder: (context, state) =>
                  _buildPage(state, const OrganizationInformationScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/leads/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        LeadDetailsScreen(leadId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/add-lead',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(state, const AddLeadScreen()),
    ),
    GoRoute(
      path: '/edit-lead/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        AddLeadScreen(leadId: state.pathParameters['id']),
      ),
    ),
    GoRoute(
      path: '/tasks/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        TaskDetailsScreen(taskId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/lead-settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const LeadSettingsScreen()),
    ),
    GoRoute(
      path: '/lead-statuses',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const LeadStatusesScreen()),
    ),
    GoRoute(
      path: '/auto-sms-settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const AutoSmsSettingsScreen()),
    ),
    GoRoute(
      path: '/lead-sources',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const LeadSourcesScreen()),
    ),
    GoRoute(
      path: '/business-types',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const BusinessTypesScreen()),
    ),
    GoRoute(
      path: '/lead-priorities',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const LeadPrioritiesScreen()),
    ),
    GoRoute(
      path: '/custom-fields',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const CustomFieldsScreen()),
    ),
    GoRoute(
      path: '/lost-reasons',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const LostReasonsScreen()),
    ),
    GoRoute(
      path: '/module-manager',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const ModuleManagerScreen()),
    ),
    GoRoute(
      path: '/departments',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const DepartmentsScreen()),
    ),
    GoRoute(
      path: '/notification-preferences',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const NotificationPreferencesScreen()),
    ),
    GoRoute(
      path: '/account-security',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const AccountSecurityScreen()),
    ),
    GoRoute(
      path: '/role-permissions',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const RolePermissionsScreen()),
    ),
    GoRoute(
      path: '/role-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        RoleDetailsScreen(roleId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/new-role',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(state, const NewRoleScreen()),
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(state, const AboutScreen()),
    ),
    GoRoute(
      path: '/permissions',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const AppPermissionsScreen()),
    ),
    GoRoute(
      path: '/appearance',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const AppearanceScreen()),
    ),
    GoRoute(
      path: '/edit-profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const EditProfileScreen()),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(state, const ProfileScreen()),
    ),
    GoRoute(
      path: '/employee/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        EmployeeProfileScreen(employeeId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/team',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(state, const TeamScreen()),
    ),
    GoRoute(
      path: '/department/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        DepartmentDetailsScreen(departmentId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/team-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        TeamDetailsScreen(teamId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/add-employee',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const AddEmployeeScreen()),
    ),
    GoRoute(
      path: '/edit-employee/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        AddEmployeeScreen(employeeId: state.pathParameters['id']),
      ),
    ),
    GoRoute(
      path: '/create-task',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const CreateTaskScreen()),
    ),
    GoRoute(
      path: '/edit-task/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        CreateTaskScreen(taskId: state.pathParameters['id']),
      ),
    ),
    GoRoute(
      path: '/activity',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const ActivityScreen()),
    ),
    GoRoute(
      path: '/follow-ups',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const FollowUpsScreen()),
    ),
    GoRoute(
      path: '/follow-up-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        FollowUpDetailsScreen(followUpId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/visits',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(state, const VisitsScreen()),
    ),
    GoRoute(
      path: '/visit-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        VisitDetailsScreen(visitId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/issues',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(state, const IssuesScreen()),
    ),
    GoRoute(
      path: '/report-issue',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const ReportIssueSheet()),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const NotificationsScreen()),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(state, const SearchScreen()),
    ),
    GoRoute(
      path: '/expenses',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPage(state, const ExpensesScreen()),
    ),
    GoRoute(
      path: '/expense-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildPage(
        state,
        ExpenseDetailsScreen(expenseId: state.pathParameters['id'] ?? ''),
      ),
    ),
  ],
);
