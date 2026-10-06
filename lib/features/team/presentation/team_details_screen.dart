import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../data/mock_employees.dart';
import '../data/employee_store.dart';
import '../domain/models/employee.dart';
import 'widgets/add_team_member_sheet.dart';
import 'widgets/team_action_sheet.dart';
import 'widgets/team_hero_card.dart';
import 'widgets/team_work_overview_card.dart';

class TeamDetailsScreen extends StatelessWidget {
  final String teamId;

  const TeamDetailsScreen({
    super.key,
    required this.teamId,
  });

  void _openActionSheet(BuildContext context, String teamName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TeamActionSheet(teamName: teamName),
    );
  }

  void _openAddMemberSheet(BuildContext context, String teamName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddTeamMemberSheet(teamName: teamName),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: EmployeeStore.instance,
      builder: (context, _) => _buildDetails(context));

  Widget _buildDetails(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final team = mockTeams.where((item) => item.id == teamId).firstOrNull;
    if (team == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Team unavailable')),
          body: const Center(child: Text('This team could not be found.')));
    }
    final teamName = team.name;
    final deptName = '${team.department} Department';
    final teamDesc = 'People and work in $teamName';
    final teamLead = mockEmployees
        .where((employee) => employee.name == team.leadName)
        .firstOrNull;
    final members =
        mockEmployees.where((employee) => employee.team == teamName).toList();

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: nec.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: nec.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  teamName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _openActionSheet(context, teamName),
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: nec.brand,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: nec.separator.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeamHeroCard(
                title: teamName,
                departmentName: deptName,
                description: teamDesc,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'TEAM LEAD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: NecAvatar(
                    initials: teamLead?.avatarInitials ??
                        Employee.initialsFor(team.leadName),
                    photoBase64: teamLead?.photoBase64,
                    size: 38,
                  ),
                  title: Text(
                    teamLead?.name ?? team.leadName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    teamLead?.designation ?? 'Team lead',
                    style: TextStyle(
                      fontSize: 12,
                      color: nec.textTertiary,
                    ),
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: teamLead == null
                      ? null
                      : () => context.push('/employee/${teamLead.id}'),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'WORK OVERVIEW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const TeamWorkOverviewCard(
                activeLeads: 10,
                followUpsDue: 5,
                visitsToday: 1,
                openTasks: 6,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'MEMBERS (${members.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: nec.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => _openAddMemberSheet(context, teamName),
                    child: Text(
                      '+ Add Member',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: nec.brand,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(members.length, (index) {
                    final emp = members[index];
                    final isLast = index == members.length - 1;
                    final isLead = emp.id == teamLead?.id;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: NecAvatar(
                            initials: emp.avatarInitials,
                            photoBase64: emp.photoBase64,
                            size: 38,
                          ),
                          title: Text(
                            emp.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            emp.designation,
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textTertiary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLead) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.leadContacted
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Lead',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.leadContacted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: nec.textTertiary,
                              ),
                            ],
                          ),
                          onTap: () => context.push('/employee/${emp.id}'),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.3),
                            indent: 68,
                          ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
