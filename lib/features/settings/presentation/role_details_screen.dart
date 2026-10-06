import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../data/mock_system_roles.dart';
import '../domain/models/system_role.dart';

class RoleDetailsScreen extends StatefulWidget {
  final String roleId;

  const RoleDetailsScreen({
    super.key,
    required this.roleId,
  });

  @override
  State<RoleDetailsScreen> createState() => _RoleDetailsScreenState();
}

class _RoleDetailsScreenState extends State<RoleDetailsScreen> {
  String _selectedTab = 'Overview';
  final Set<String> _expandedModules = {'Leads', 'Visits'};

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final role = getRoleById(widget.roleId);

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
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.pop();
                  }
                },
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
                  role.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 68),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: role.iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              CupertinoIcons.shield_fill,
                              color: role.iconColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      role.name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: nec.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: nec.separator
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        role.badge,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: nec.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  role.description,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: nec.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildStatCard(nec, '${role.memberCount}', 'Members',
                            AppColors.brandLight),
                        const SizedBox(width: 10),
                        _buildStatCard(nec, '${role.modulePermissions.length}',
                            'Modules', AppColors.brandLight),
                        const SizedBox(width: 10),
                        _buildStatCard(nec, role.lastUpdated.split(',')[0],
                            'Updated', AppColors.brandLight),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSubTabBar(nec, role.memberCount),
                    const SizedBox(height: 16),
                    if (_selectedTab == 'Overview')
                      _buildOverviewTab(nec, role)
                    else if (_selectedTab == 'Members')
                      _buildMembersTab(nec, role)
                    else
                      _buildPermissionsTab(nec, role),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    NecColors nec,
    String value,
    String label,
    Color valueColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: nec.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: nec.separator.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: nec.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabBar(NecColors nec, int memberCount) {
    final tabs = ['Overview', 'Members ($memberCount)', 'Permissions'];
    final tabKeys = ['Overview', 'Members', 'Permissions'];
    final activeIndex = tabKeys.indexOf(_selectedTab);

    return Column(
      children: [
        Row(
          children: List.generate(tabs.length, (idx) {
            final label = tabs[idx];
            final key = tabKeys[idx];
            final isSelected = _selectedTab == key;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedTab = key;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected ? AppColors.brandLight : nec.textTertiary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 3;
            return Stack(
              children: [
                Container(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.3),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: tabWidth * activeIndex,
                  width: tabWidth,
                  height: 2.5,
                  child: Container(
                    color: AppColors.brandLight,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewTab(NecColors nec, SystemRoleItem role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: nec.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildOverviewRow(nec, 'Role Type',
                  role.badge == 'SYSTEM' ? 'System' : 'Custom'),
              Divider(
                height: 1,
                color: nec.separator.withValues(alpha: 0.2),
                indent: 16,
              ),
              _buildOverviewRow(nec, 'Scope', role.scope),
              Divider(
                height: 1,
                color: nec.separator.withValues(alpha: 0.2),
                indent: 16,
              ),
              _buildOverviewRow(
                  nec, 'Members', '${role.memberCount} employees'),
              Divider(
                height: 1,
                color: nec.separator.withValues(alpha: 0.2),
                indent: 16,
              ),
              _buildOverviewRow(nec, 'Last Updated', role.lastUpdated),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'PERMISSION SUMMARY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: nec.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: nec.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(role.modulePermissions.length, (idx) {
              final mod = role.modulePermissions[idx];
              final isLast = idx == role.modulePermissions.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: mod.dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              mod.moduleName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: nec.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          mod.accessLevel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewRow(NecColors nec, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: nec.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: nec.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(NecColors nec, SystemRoleItem role) {
    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(role.memberNames.length, (idx) {
          final name = role.memberNames[idx];
          final initials = name.split(' ').map((w) => w[0]).take(2).join();
          final isLast = idx == role.memberNames.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: NecAvatar(
                  initials: initials,
                  size: 36,
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.2),
                  indent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPermissionsTab(NecColors nec, SystemRoleItem role) {
    return Column(
      children: List.generate(role.modulePermissions.length, (idx) {
        final mod = role.modulePermissions[idx];
        final isExpanded = _expandedModules.contains(mod.moduleName);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedModules.remove(mod.moduleName);
                    } else {
                      _expandedModules.add(mod.moduleName);
                    }
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: mod.dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            mod.moduleName,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: nec.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            mod.accessLevel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isExpanded
                                ? CupertinoIcons.chevron_up
                                : CupertinoIcons.chevron_down,
                            size: 14,
                            color: nec.textTertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.2),
                ),
                ...mod.permissions.map(
                  (perm) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: nec.separator.withValues(alpha: 0.15),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          perm.$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: nec.textPrimary,
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}
