import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class AdministrationScreen extends StatefulWidget {
  const AdministrationScreen({super.key});

  @override
  State<AdministrationScreen> createState() => _AdministrationScreenState();
}

class _AdministrationScreenState extends State<AdministrationScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _searchController.text.trim().toLowerCase();

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
                onPressed: () => context.popAppRoute(),
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
                  'Administration',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSearchField(
                controller: _searchController,
                isDark: isDark,
                nec: nec,
              ),
              const SizedBox(height: 20),
              if (_matchesSection(query, [
                'employees',
                'departments',
                'teams',
                'attendance',
                'lunch',
                'meal',
                'leave',
                'overtime',
                'off day',
                'people & organization'
              ])) ...[
                _buildSectionHeader(nec, 'PEOPLE & ORGANIZATION'),
                AdminGroupCard(
                  items: [
                    if (_matchesItem(query, 'lunch management',
                        'meals staff office lunch counts'))
                      AdminRowItem(
                        icon: CupertinoIcons.cart,
                        iconColor: const Color(0xFFFF9F0A),
                        title: 'Lunch Management',
                        subtitle: 'Daily lunch counts and staff preferences',
                        onTap: () => context.push('/meals/admin'),
                      ),
                    if (_matchesItem(query, 'attendance management',
                        'leave overtime off day swaps attendance fixes'))
                      AdminRowItem(
                        icon: CupertinoIcons.calendar,
                        iconColor: const Color(0xFF34C759),
                        title: 'Attendance Management',
                        subtitle:
                            'Staff attendance, requests, reports and settings',
                        onTap: () => context.push('/attendance/admin'),
                      ),
                    if (_matchesItem(
                        query, 'employees', 'employee accounts access'))
                      AdminRowItem(
                        icon: CupertinoIcons.person_2_fill,
                        iconColor: const Color(0xFF5856D6),
                        title: 'Employees',
                        subtitle: 'Manage employee accounts and access',
                        onTap: () => context.push('/team'),
                      ),
                    if (_matchesItem(
                        query, 'departments', 'organize company departments'))
                      AdminRowItem(
                        icon: CupertinoIcons.briefcase_fill,
                        iconColor: const Color(0xFF30B0C7),
                        title: 'Departments',
                        subtitle: 'Organize company departments',
                        onTap: () => context.push('/departments'),
                      ),
                    if (_matchesItem(query, 'teams', 'reporting structure'))
                      AdminRowItem(
                        icon: CupertinoIcons.person_3_fill,
                        iconColor: AppColors.brandLight,
                        title: 'Teams',
                        subtitle: 'Manage teams and reporting structure',
                        onTap: () => context.push('/team'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (_matchesSection(
                  query, ['roles', 'permissions', 'access control'])) ...[
                _buildSectionHeader(nec, 'ACCESS CONTROL'),
                AdminGroupCard(
                  items: [
                    AdminRowItem(
                      icon: CupertinoIcons.shield_fill,
                      iconColor: const Color(0xFFAF52DE),
                      title: 'Roles & Permissions',
                      subtitle: 'Configure what each role can access',
                      onTap: () => context.push('/role-permissions'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (_matchesSection(query, ['modules', 'module manager'])) ...[
                _buildSectionHeader(nec, 'MODULES'),
                AdminGroupCard(
                  items: [
                    AdminRowItem(
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      iconColor: AppColors.warning,
                      title: 'Module Manager',
                      subtitle: 'Enable or disable product modules',
                      onTap: () => context.push('/module-manager'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (_matchesSection(query, [
                'operations',
                'lead settings',
                'follow-up',
                'visit settings',
                'task settings',
                'issue settings'
              ])) ...[
                _buildSectionHeader(nec, 'OPERATIONS'),
                AdminGroupCard(
                  items: [
                    if (_matchesItem(
                        query, 'lead settings', 'statuses sources'))
                      AdminRowItem(
                        icon: CupertinoIcons.person_2_fill,
                        iconColor: AppColors.brandLight,
                        title: 'Lead Settings',
                        showStar: true,
                        subtitle: 'Statuses, sources, fields, lost reasons',
                        onTap: () => context.push('/lead-settings'),
                      ),
                    if (_matchesSection(query, [
                      'operations settings',
                      'follow-up',
                      'follow-ups',
                      'follow-up & visit settings',
                      'visit',
                      'visits',
                      'visit settings',
                      'task',
                      'tasks',
                      'task settings',
                      'issue',
                      'issues',
                      'issue settings',
                    ]))
                      AdminRowItem(
                        icon: CupertinoIcons.slider_horizontal_3,
                        iconColor: AppColors.brandLight,
                        title: 'Operations Settings',
                        subtitle:
                            'Configure follow-ups, visits, tasks and issues',
                        onTap: () => context.push('/operations-settings'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (_matchesSection(
                  query, ['communication', 'notification settings'])) ...[
                _buildSectionHeader(nec, 'COMMUNICATION'),
                AdminGroupCard(
                  items: [
                    AdminRowItem(
                      icon: CupertinoIcons.bell_fill,
                      iconColor: AppColors.brandLight,
                      title: 'System Notification Settings',
                      subtitle: 'Configure system-level notification events',
                      onTap: () => context.push('/notification-preferences'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (_matchesSection(
                  query, ['system', 'audit logs', 'system settings'])) ...[
                _buildSectionHeader(nec, 'SYSTEM'),
                AdminGroupCard(
                  items: [
                    if (_matchesItem(query, 'audit logs', 'change history'))
                      AdminRowItem(
                        icon: CupertinoIcons.waveform_path_ecg,
                        iconColor: const Color(0xFF8E8E93),
                        title: 'Audit Logs',
                        subtitle: 'Administrative change history',
                        onTap: () => context.push('/audit-logs'),
                      ),
                    if (_matchesItem(query, 'system settings',
                        'organization security policy'))
                      AdminRowItem(
                        icon: CupertinoIcons.gear_alt_fill,
                        iconColor: const Color(0xFF8E8E93),
                        title: 'System Settings',
                        subtitle: 'Organization, defaults, security policy',
                        onTap: () => context.push('/system-settings'),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesSection(String query, List<String> keywords) {
    if (query.isEmpty) return true;
    return keywords.any((k) => k.contains(query) || query.contains(k));
  }

  bool _matchesItem(String query, String title, String subtitle) {
    if (query.isEmpty) return true;
    return title.toLowerCase().contains(query) ||
        subtitle.toLowerCase().contains(query);
  }

  Widget _buildSectionHeader(NecColors nec, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: nec.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final NecColors nec;

  const AdminSearchField({
    super.key,
    required this.controller,
    required this.isDark,
    required this.nec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? nec.surface : nec.separator.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: nec.separator.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.search,
            size: 18,
            color: nec.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 15,
                color: nec.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search settings',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: nec.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () => controller.clear(),
              child: Icon(
                CupertinoIcons.clear_thick_circled,
                size: 18,
                color: nec.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class AdminGroupCard extends StatelessWidget {
  final List<AdminRowItem> items;

  const AdminGroupCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final filtered = items.where((i) => i.title.isNotEmpty).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(filtered.length, (index) {
          final item = filtered[index];
          final isLast = index == filtered.length - 1;

          return Column(
            children: [
              item,
              if (!isLast)
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.2),
                  indent: 66,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class AdminRowItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool showStar;
  final String subtitle;
  final VoidCallback onTap;

  const AdminRowItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.showStar = false,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                      ),
                      if (showStar) ...[
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.star_fill,
                          size: 12,
                          color: nec.textPrimary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: nec.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: nec.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
