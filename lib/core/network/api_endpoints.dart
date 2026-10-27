class ApiEndpoints {
  ApiEndpoints._();

  static const login = '/team-operations/auth/login';
  static const me = '/team-operations/me';
  static const profile = '/team-operations/profile';
  static const changePassword = '/team-operations/change-password';
  static const signOut = '/team-operations/account-security/sign-out';
  static const departments = '/super-admin/team-operations/departments';
  static const employees = '/super-admin/team-operations/employees';
  static const addEmployee = '/team-operations/team/employees';
  static const roles = '/team-operations/administration/roles';

  static String role(String id) => '$roles/${Uri.encodeComponent(id)}';
  static const administration = '/team-operations/administration';
  static const permissionCatalog = '$administration/permissions';

  static String employee(String id) =>
      '$addEmployee/${Uri.encodeComponent(id)}';

  static String employeeAccess(String id) => '${employee(id)}/access';
  static const team = '/team-operations/team';
  static const teams = '$team/teams';

  static String teamDetails(String name) =>
      '$team/teams/${Uri.encodeComponent(name)}';

  static String department(String id) =>
      '$departments/${Uri.encodeComponent(id)}';

  static String departmentDetails(String id) =>
      '/team-operations/team/departments/${Uri.encodeComponent(id)}';

  static String departmentMembers(String id) =>
      '${departmentDetails(id)}/members';

  static String departmentMember(String id, String employeeId) =>
      '${departmentMembers(id)}/${Uri.encodeComponent(employeeId)}';
  static const leads = '/super-admin/team-operations/leads';

  static String lead(String id) => '$leads/${Uri.encodeComponent(id)}';
  static const workItems = '/super-admin/team-operations/work-items';

  static String workItem(String id) => '$workItems/${Uri.encodeComponent(id)}';
  static const staffWorkItems = '/team-operations/work-items';
  static const overview = '/super-admin/team-operations/overview';

  /// Mobile App - Team Operations
  static const employeeDashboard = '/team-operations/employee-dashboard';
  static const accountSecurity = '/team-operations/account-security';
  static const moreSummary = '/team-operations/more';
  static const myAccess = '/team-operations/my-access';
  static const userSettings = '/team-operations/user-settings';
  static const activityFeed = '/team-operations/activity';
  static const notifications = '/team-operations/notifications';

  static String markNotificationRead(String id) =>
      '$notifications/${Uri.encodeComponent(id)}/read';
  static const markAllNotificationsRead = '$notifications/read-all';
  static const pushDevices = '/team-operations/push-devices';
  static const pushNotificationPreferences =
      '/team-operations/push-notification-preferences';
  static const staffOverview = '/team-operations/overview';
  static const staffLeads = '/team-operations/leads';

  static String staffLead(String id) =>
      '$staffLeads/${Uri.encodeComponent(id)}';
  static const leadOptions = '/team-operations/leads/options';

  static String leadNotes(String id) =>
      '$staffLeads/${Uri.encodeComponent(id)}/notes';

  static String leadAttachments(String id) =>
      '$staffLeads/${Uri.encodeComponent(id)}/attachments';

  static String leadAttachment(String leadId, String attachmentId) =>
      '$staffLeads/${Uri.encodeComponent(leadId)}/attachments/${Uri.encodeComponent(attachmentId)}';
  static const workItemOptions = '/team-operations/work-items/options';

  static String workItemComments(String id) =>
      '$staffWorkItems/${Uri.encodeComponent(id)}/comments';

  static String workItemAttachments(String id) =>
      '$staffWorkItems/${Uri.encodeComponent(id)}/attachments';

  static String workItemAttachment(String workId, String attachmentId) =>
      '$staffWorkItems/${Uri.encodeComponent(workId)}/attachments/${Uri.encodeComponent(attachmentId)}';

  static String followUpDetail(String id) =>
      '/team-operations/follow-ups/${Uri.encodeComponent(id)}';

  static String completeFollowUp(String id) =>
      '/team-operations/follow-ups/${Uri.encodeComponent(id)}/complete';

  static String rescheduleFollowUp(String id) =>
      '/team-operations/follow-ups/${Uri.encodeComponent(id)}/reschedule';

  static String visitDetail(String id) =>
      '/team-operations/visits/${Uri.encodeComponent(id)}';

  static String startVisitJourney(String id) =>
      '/team-operations/visits/${Uri.encodeComponent(id)}/start-journey';

  static String markVisitArrived(String id) =>
      '/team-operations/visits/${Uri.encodeComponent(id)}/mark-arrived';

  static String completeVisitReport(String id) =>
      '/team-operations/visits/${Uri.encodeComponent(id)}/complete';

  static String rescheduleVisit(String id) =>
      '/team-operations/visits/${Uri.encodeComponent(id)}/reschedule';

  static String cancelVisit(String id) =>
      '/team-operations/visits/${Uri.encodeComponent(id)}/cancel';
  static const adminSettings = '/team-operations/administration/settings';
  static const adminLeadSettings =
      '/team-operations/administration/lead-settings';
  static const adminOperationsSettings =
      '/team-operations/administration/operations-settings';
  static const adminSystemSettings =
      '/team-operations/administration/system-settings';

  static String adminSettingCategory(String category) =>
      '$adminSettings/${Uri.encodeComponent(category)}';

  static String adminSettingItem(String category, String key) =>
      '$adminSettings/${Uri.encodeComponent(category)}/${Uri.encodeComponent(key)}';

  /// Attendance
  static const attendance = '/team-operations/attendance';
  static const attendanceCheckIn = '/team-operations/attendance/check-in';
  static const attendanceBreakStart = '/team-operations/attendance/break/start';
  static const attendanceBreakEnd = '/team-operations/attendance/break/end';
  static const attendanceCheckOut = '/team-operations/attendance/check-out';
  static const attendanceRequests = '/team-operations/attendance/requests';
  static const attendanceAdminRequests =
      '/team-operations/attendance/admin/requests';

  static String attendanceAdminReviewRequest(String id) =>
      '$attendanceAdminRequests/${Uri.encodeComponent(id)}';
  static const attendanceAdminOverview =
      '/team-operations/attendance/admin/overview';
  static const attendanceAdminStaff = '/team-operations/attendance/admin/staff';

  static String attendanceAdminEmployee(String id) =>
      '/team-operations/attendance/admin/employees/${Uri.encodeComponent(id)}';
  static const attendanceAdminReports =
      '/team-operations/attendance/admin/reports';
  static const attendanceAdminLunch = '/team-operations/attendance/admin/lunch';

  static String attendanceAdminManageLunch(String employeeId) =>
      '$attendanceAdminLunch/${Uri.encodeComponent(employeeId)}';
  static const attendanceAdminSettings =
      '/team-operations/attendance/admin/settings';
  static const attendanceAdminHolidays =
      '/team-operations/attendance/admin/holidays';

  /// Office Lunch
  static const officeLunch = '/team-operations/office-lunch';
  static const lunchToday = '/team-operations/lunch/today';
  static const lunchToggle = '/team-operations/lunch/toggle';
  static const lunchMonthly = '/team-operations/lunch/monthly-summary';
  static const lunchRoster = '/team-operations/lunch/admin/roster';
  static const lunchSettings = '/team-operations/lunch/admin/settings';
  static const attendanceToday = '/team-operations/attendance/today';
  static const attendanceHistory = '/team-operations/attendance/history';
  static const myDepartment = '/team-operations/my-department';
  static const myTeam = '/team-operations/my-team';
  static const automatedSms = '/team-operations/administration/automated-sms';

  static String employeeLifecycle(String id, String action) =>
      '${employee(id)}/$action';

  /// Messages & Conversations
  static const messages = '/team-operations/messages';

  static String conversation(String id) =>
      '$messages/${Uri.encodeComponent(id)}';

  static String sendMessage(String conversationId) =>
      '$messages/${Uri.encodeComponent(conversationId)}/send';

  static String archiveConversation(String conversationId) =>
      '$messages/${Uri.encodeComponent(conversationId)}/archive';

  static String messageReactions(String messageId) =>
      '$messages/items/${Uri.encodeComponent(messageId)}/reactions';

  static String messagePin(String messageId) =>
      '$messages/items/${Uri.encodeComponent(messageId)}/pin';

  static String messageItem(String messageId) =>
      '$messages/items/${Uri.encodeComponent(messageId)}';
  static const messageRecipients = '$messages/recipients';

  static String removeGroupMember(String conversationId, String userId) =>
      '$messages/${Uri.encodeComponent(conversationId)}/members/${Uri.encodeComponent(userId)}';
  static const pushDeliveries = '/team-operations/push-deliveries';
}
