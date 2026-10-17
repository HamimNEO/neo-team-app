import 'widgets/edit_team_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/team_store.dart';
import '../../../core/services/demo_session.dart';
import '../data/employee_store.dart';
import '../domain/models/employee.dart';
import '../domain/models/team_group.dart';
import 'widgets/add_team_member_sheet.dart';
import 'widgets/team_action_sheet.dart';
import 'widgets/team_hero_card.dart';
import 'widgets/team_work_overview_card.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailsScreen({
    super.key,
    required this.teamId,
  });

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final _store = TeamStore.instance;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    EmployeeStore.instance.addListener(_refresh);
    _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String? _localPhoto(Employee? employee) {
    if (employee == null) return null;
    final cached = EmployeeStore.instance.byId(employee.id);
    return cached?.photoUrl == employee.photoUrl ? cached?.photoBase64 : null;
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await EmployeeStore.instance.load();
      await _store.load();
      await _store.details(widget.teamId);
    } catch (e) {
      if (mounted) _error = EmployeeStore.messageFor(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    EmployeeStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _openActionSheet(BuildContext context, String teamName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TeamActionSheet(
          teamName: teamName,
          onDelete: _store.detailFor(widget.teamId)?.team.backendId == null
              ? null
              : () => _deleteTeam(_store.detailFor(widget.teamId)!.team),
          onEdit: _store.detailFor(widget.teamId)?.team.backendId == null
              ? null
              : () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => EditTeamSheet(
                      team: _store.detailFor(widget.teamId)!.team)),
          onAddMember: () => _openAddMemberSheet(context, teamName)),
    );
  }

  Future<void> _deleteTeam(TeamGroup team) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Delete Team'),
                content: Text(
                    'Delete ${team.name}? The server will check whether this team can be deleted.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'))
                ]));
    if (confirmed != true || !mounted) return;
    try {
      await _store.delete(team);
      if (!mounted) return;
      NecToast.show(context,
          message: 'Team deleted', type: NecToastType.success);
      context.pop();
    } catch (e) {
      if (mounted) {
        NecToast.show(context,
            message: EmployeeStore.messageFor(e), type: NecToastType.error);
      }
    }
  }

  void _openAddMemberSheet(BuildContext context, String teamName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          AddTeamMemberSheet(teamName: teamName, onMemberAdded: (_) => _load()),
    );
  }

  @override
  Widget build(BuildContext context) => _buildDetails(context);

  Widget _buildDetails(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final detail = _store.detailFor(widget.teamId);
    final team = detail?.team ??
        _store.teams.where((item) => item.id == widget.teamId).firstOrNull;
    if (team == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Team unavailable')),
          body: Center(
              child: _loading
                  ? const CupertinoActivityIndicator()
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error ?? 'This team could not be found.'),
                      TextButton(onPressed: _load, child: const Text('Retry'))
                    ])));
    }
    final teamName = team.name;
    final deptName = team.department;
    final teamDesc = team.description ?? '';
    final teamLead = team.lead;
    final members = detail?.members ?? <Employee>[];
    final work = team.workOverview;

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
              if (DemoSession.instance.isAdmin)
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
        child: RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  if (_error != null)
                    Column(children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child: const Text('Retry'))
                    ]),
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
                        photoBase64: _localPhoto(teamLead),
                        photoUrl: teamLead?.photoUrl,
                        assetPath: teamLead?.avatarAsset,
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
                  if (work != null) ...[
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
                    TeamWorkOverviewCard(
                      activeLeads: work['active_leads'],
                      followUpsDue: work['followups_due'],
                      visitsToday: work['visits_today'],
                      openTasks: work['open_tasks'],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'MEMBERS (${team.memberCount})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (DemoSession.instance.isAdmin)
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: () =>
                              _openAddMemberSheet(context, teamName),
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
                                photoBase64: _localPhoto(emp),
                                photoUrl: emp.photoUrl,
                                assetPath: emp.avatarAsset,
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
            )),
      ),
    );
  }
}
