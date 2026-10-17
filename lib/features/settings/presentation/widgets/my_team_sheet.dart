import '../../data/my_workspace_store.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../team/domain/models/employee.dart';

/// Modal bottom sheet displaying detailed team information and fellow team members.
class MyTeamSheet extends StatefulWidget {
  final Employee currentEmployee;

  const MyTeamSheet({super.key, required this.currentEmployee});

  static void show(BuildContext context, Employee currentEmployee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MyTeamSheet(currentEmployee: currentEmployee),
    );
  }

  @override
  State<MyTeamSheet> createState() => _MyTeamSheetState();
}

class _MyTeamSheetState extends State<MyTeamSheet> {
  String _searchQuery = '';
  final _workspace = MyWorkspaceStore.instance;

  @override
  void initState() {
    super.initState();
    _workspace.addListener(_refresh);
    _workspace.load(force: true);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _workspace.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final myTeamName = _workspace.team['name']?.toString() ??
        (widget.currentEmployee.team.isEmpty
            ? 'Unassigned team'
            : widget.currentEmployee.team);
    final teamMembers = List<Employee>.of(_workspace.teamMembers);

    teamMembers.sort((a, b) {
      if (a.id == widget.currentEmployee.id) return -1;
      if (b.id == widget.currentEmployee.id) return 1;
      return a.name.compareTo(b.name);
    });

    final filteredMembers = _searchQuery.isEmpty
        ? teamMembers
        : teamMembers.where((m) {
            final q = _searchQuery.toLowerCase();
            return m.name.toLowerCase().contains(q) ||
                m.designation.toLowerCase().contains(q) ||
                m.email.toLowerCase().contains(q);
          }).toList();

    final lead = _workspace.team['lead'];
    final teamLeadName =
        lead is Map ? lead['name']?.toString() ?? 'Unassigned' : 'Unassigned';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_workspace.loading) const LinearProgressIndicator(minHeight: 2),
          if (_workspace.error != null)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Text(_workspace.error!, textAlign: TextAlign.center),
                  TextButton(
                      onPressed: () => _workspace.load(force: true),
                      child: const Text('Retry')),
                ])),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: nec.separator.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5856D6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_3_fill,
                    color: Color(0xFF5856D6),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Team',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5856D6),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        myTeamName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: nec.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.xmark_circle_fill,
                      color: nec.textTertiary, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: nec.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: nec.separator.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team Lead: $teamLeadName',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Dept: ${widget.currentEmployee.department.split(' · ').first}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: nec.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5856D6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${teamMembers.length} Members',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5856D6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (teamMembers.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: nec.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.search,
                        size: 15, color: nec.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(fontSize: 13, color: nec.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search team colleagues...',
                          hintStyle:
                              TextStyle(fontSize: 13, color: nec.textTertiary),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TEAM MEMBERS & DESIGNATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: nec.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${filteredMembers.length} listed',
                  style: TextStyle(
                    fontSize: 11,
                    color: nec.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: filteredMembers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final emp = filteredMembers[index];
                final isMe = emp.id == widget.currentEmployee.id;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF5856D6).withValues(alpha: 0.05)
                        : nec.surfaceSecondary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMe
                          ? const Color(0xFF5856D6).withValues(alpha: 0.3)
                          : nec.separator.withValues(alpha: 0.15),
                      width: isMe ? 1.2 : 0.6,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              const Color(0xFF5856D6).withValues(alpha: 0.12),
                        ),
                        child: ClipOval(
                          child: _buildAvatar(emp, nec),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    emp.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5856D6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'YOU',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              emp.designation.isNotEmpty
                                  ? emp.designation
                                  : 'Team Member',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: nec.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (emp.email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                emp.email,
                                style: TextStyle(
                                  fontSize: 11.5,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          emp.status.isNotEmpty
                              ? emp.status.toUpperCase()
                              : 'ACTIVE',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Employee emp, NecColors nec) {
    if (emp.photoBase64 != null && emp.photoBase64!.isNotEmpty) {
      try {
        return Image.memory(base64Decode(emp.photoBase64!), fit: BoxFit.cover);
      } catch (_) {}
    }
    if (emp.photoUrl != null && emp.photoUrl!.isNotEmpty) {
      return Image.network(
        emp.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(emp.avatarInitials, nec),
      );
    }
    return _buildInitials(emp.avatarInitials, nec);
  }

  Widget _buildInitials(String initials, NecColors nec) {
    return Center(
      child: Text(
        initials.isNotEmpty ? initials : 'EM',
        style: const TextStyle(
          color: Color(0xFF5856D6),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
