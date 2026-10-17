import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../team/data/department_store.dart';
import '../../../team/data/employee_store.dart';
import '../../../team/data/team_store.dart';
import '../../../team/domain/models/employee.dart';

/// Workspace identity and organization summary at the top of More.
class WorkspaceHeroCard extends StatelessWidget {
  const WorkspaceHeroCard({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([
          DemoSession.instance,
          EmployeeStore.instance,
          DepartmentStore.instance,
          TeamStore.instance,
        ]),
        builder: (context, _) => _buildCard(context),
      );

  Widget _buildCard(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = DemoSession.instance;
    final isAdmin = session.isAdmin;

    final empStore = EmployeeStore.instance;
    final currentEmp = empStore.byId(session.employeeId);

    final name = (currentEmp?.name.isNotEmpty == true)
        ? currentEmp!.name
        : (session.user?.name.isNotEmpty == true
            ? session.user!.name
            : (isAdmin ? 'Super Admin' : 'Employee'));

    final employeeDesignation = currentEmp?.designation.trim() ?? '';
    final designation = isAdmin
        ? 'Executive Administrator'
        : (employeeDesignation.isNotEmpty ? employeeDesignation : 'Employee');

    final department = (currentEmp?.department.isNotEmpty == true)
        ? currentEmp!.department.split(' · ').first
        : (isAdmin ? 'Operations & Executive' : 'Department');

    final team = (currentEmp?.team.isNotEmpty == true)
        ? currentEmp!.team
        : (isAdmin ? 'Administration Core' : 'Assigned Team');

    final email = session.email.isNotEmpty
        ? session.email
        : (currentEmp?.email.isNotEmpty == true
            ? currentEmp!.email
            : (isAdmin ? 'dragon@bingi.com.bd' : ''));

    final deptCount = DepartmentStore.instance.departments.length;
    final teamCount = TeamStore.instance.teams.length;
    final activeLeads = currentEmp?.activeLeadsCount ?? 0;
    final activeTasks = currentEmp?.activeTasksCount ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : nec.separator.withValues(alpha: 0.18),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.push('/profile'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isAdmin
                                  ? const [Color(0xFF0284C7), Color(0xFF38BDF8)]
                                  : const [
                                      Color(0xFF8A52F3),
                                      Color(0xFFC782FE),
                                      Color(0xFF5582FF)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: nec.surface,
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            padding: const EdgeInsets.all(1.5),
                            child: ClipOval(
                              child: isAdmin
                                  ? Image.asset(
                                      AppConstants.superAdminAvatarAsset,
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.high,
                                    )
                                  : _buildEmployeeAvatar(currentEmp, nec),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              shape: BoxShape.circle,
                              border: Border.all(color: nec.surface, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textPrimary,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildRoleBadge(isAdmin, isDark),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            designation,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: nec.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : nec.surfaceSecondary.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.25)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _buildGridChip(
                      icon: CupertinoIcons.building_2_fill,
                      title: isAdmin ? '$deptCount' : department,
                      subtitle: isAdmin ? 'Departments' : 'Department',
                      isAdmin: isAdmin,
                      isDark: isDark,
                      nec: nec,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGridChip(
                      icon: CupertinoIcons.person_3_fill,
                      title: isAdmin ? '$teamCount' : team,
                      subtitle: isAdmin ? 'Teams' : 'Team',
                      isAdmin: isAdmin,
                      isDark: isDark,
                      nec: nec,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _buildHighlightCard(
                isAdmin: isAdmin,
                isDark: isDark,
                activeLeads: activeLeads,
                activeTasks: activeTasks,
                nec: nec,
                onTap: () =>
                    context.push(isAdmin ? '/administration' : '/my-access'),
              ),
            ),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.25)),
            InkWell(
              onTap: () => context.push(
                isAdmin ? '/administration' : '/my-access',
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      isAdmin
                          ? CupertinoIcons.slider_horizontal_3
                          : CupertinoIcons.square_grid_2x2,
                      size: 18,
                      color: _getAccentColor(isAdmin, isDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAdmin
                            ? 'Manage organization, roles & directory'
                            : 'Explore My Department, My Teams & Access',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _getAccentColor(isAdmin, isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: _getAccentColor(isAdmin, isDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(bool isAdmin, bool isDark) {
    final bg = isAdmin
        ? (isDark ? const Color(0xFF0F3854) : const Color(0xFFE0F2FE))
        : (isDark ? const Color(0xFF3B1D5A) : const Color(0xFFF3E8FF));
    final fg = isAdmin
        ? (isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7))
        : (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.workspace_premium : CupertinoIcons.person_fill,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin ? 'ADMIN' : 'Employee',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridChip({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isAdmin,
    required bool isDark,
    required NecColors nec,
  }) {
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : (isAdmin ? const Color(0xFFE0F2FE) : const Color(0xFFF3E8FF));
    final iconFg = isAdmin
        ? (isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7))
        : (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : nec.surfaceSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: nec.separator.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: nec.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({
    required bool isAdmin,
    required bool isDark,
    required int activeLeads,
    required int activeTasks,
    required NecColors nec,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? const Color(0xFF131D33) : const Color(0xFFF0F5FF);
    final cardBorder =
        isDark ? const Color(0xFF1E2D4A) : const Color(0xFFDBEAFE);
    final iconBg = isDark ? const Color(0xFF1E2F54) : const Color(0xFFDBEAFE);
    final textFg = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);

    final title = isAdmin
        ? 'Full Organization Control'
        : '$activeLeads Leads · $activeTasks Tasks';
    final subtitle = isAdmin
        ? 'Manage all modules, users and settings'
        : 'Your current assignments';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isAdmin
                    ? CupertinoIcons.shield_fill
                    : CupertinoIcons.briefcase_fill,
                size: 18,
                color: textFg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textFg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: nec.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: textFg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccentColor(bool isAdmin, bool isDark) {
    if (isAdmin) {
      return isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
    } else {
      return isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE);
    }
  }

  Widget _buildEmployeeAvatar(Employee? emp, NecColors nec) {
    final initials = emp != null ? emp.avatarInitials : 'ME';
    Widget avatarContent;
    if (emp?.photoBase64 != null && emp!.photoBase64!.isNotEmpty) {
      try {
        avatarContent = Image.memory(
          base64Decode(emp.photoBase64!),
          fit: BoxFit.cover,
        );
      } catch (_) {
        avatarContent = _buildInitials(initials, nec);
      }
    } else if (emp?.photoUrl != null && emp!.photoUrl!.isNotEmpty) {
      avatarContent = Image.network(
        emp.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(initials, nec),
      );
    } else {
      avatarContent = _buildInitials(initials, nec);
    }
    return ClipOval(child: avatarContent);
  }

  Widget _buildInitials(String initials, NecColors nec) {
    return Container(
      decoration: BoxDecoration(
        color: nec.brand.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: nec.brand,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
