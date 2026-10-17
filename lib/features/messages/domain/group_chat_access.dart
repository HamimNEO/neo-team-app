import 'models/group_chat.dart';

/// The server must enforce the same policy when chat APIs become available.
class GroupChatAccess {
  static String employeeKey(String id) => id.replaceFirst('api_emp_', '');

  static bool canManage(ChatScope scope,
          {required bool signedIn,
          required bool admin,
          required String employeeId}) =>
      signedIn && admin;

  static bool canParticipate(ChatScope scope,
      {required bool signedIn,
      required bool admin,
      required String employeeId,
      required String team,
      required String department,
      String? departmentId}) {
    if (!signedIn) return false;
    if (canManage(scope,
        signedIn: signedIn, admin: admin, employeeId: employeeId)) {
      return true;
    }
    if (scope.kind == GroupChatKind.team) {
      return team.isNotEmpty && team == scope.id;
    }
    return departmentId != null && departmentId.isNotEmpty
        ? departmentId == scope.id
        : department.isNotEmpty && department == scope.name;
  }
}
