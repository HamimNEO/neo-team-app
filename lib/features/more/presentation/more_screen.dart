import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/services/staff_access_store.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _neutralBg = Color(0x26787880);

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Scaffold(
      backgroundColor: nec.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: nec.bg,
            title: Text(
              'More',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Material(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push(
                        DemoSession.instance.isAdmin
                            ? '/administration'
                            : '/my-access',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: nec.brand.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                DemoSession.instance.isAdmin
                                    ? CupertinoIcons.shield_fill
                                    : CupertinoIcons.person_crop_circle_badge_checkmark,
                                color: nec.brand,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${DemoSession.instance.roleLabel} Workspace',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DemoSession.instance.email.isNotEmpty
                                        ? DemoSession.instance.email
                                        : (DemoSession.instance.isAdmin
                                            ? 'Full administration'
                                            : 'Role-based access permissions'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: nec.textTertiary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                    ),
                  ),
                ),
                GroupedSection(
                  title: 'Work',
                  children: [
                    if (StaffAccessStore.instance.canOpen('/meals'))
                      SettingsRow(
                        icon: const Icon(CupertinoIcons.cart),
                        iconBg: const Color(0x2634C759),
                        title: 'My Office Lunch',
                        onTap: () => context.push('/meals'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/attendance'))
                      SettingsRow(
                        icon: const Icon(CupertinoIcons.clock),
                        iconBg: const Color(0x26007AFF),
                        iconColor: AppColors.brandLight,
                        title: 'My Attendance',
                        onTap: () => context.push('/attendance'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/follow-ups'))
                      SettingsRow(
                        icon: const Icon(Icons.reply_outlined),
                        iconBg: _neutralBg,
                        title: 'Follow-ups',
                        onTap: () => context.push('/follow-ups'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/visits'))
                      SettingsRow(
                        icon: const Icon(Icons.home_work_outlined),
                        iconBg: _neutralBg,
                        title: 'Visits',
                        onTap: () => context.push('/visits'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/issues'))
                      SettingsRow(
                        icon: const Icon(Icons.report_outlined),
                        iconBg: _neutralBg,
                        title: 'Issues',
                        onTap: () => context.push('/issues'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/team'))
                      SettingsRow(
                        icon: const Icon(Icons.group_outlined),
                        iconBg: _neutralBg,
                        title: 'Team',
                        onTap: () => context.push('/team'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/activity'))
                      SettingsRow(
                        icon: const Icon(Icons.timeline_outlined),
                        iconBg: _neutralBg,
                        title: 'Activity',
                        onTap: () => context.push('/activity'),
                        showSeparator: false,
                      ),
                  ],
                ),
                GroupedSection(
                  title: 'Personal',
                  children: [
                    SettingsRow(
                      icon: const Icon(Icons.notifications_outlined),
                      iconBg: const Color(0x26007AFF),
                      iconColor: AppColors.brandLight,
                      title: 'Notifications',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '4',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      onTap: () => context.push('/notifications'),
                    ),
                    SettingsRow(
                      icon: const Icon(Icons.person_outline),
                      iconBg: _neutralBg,
                      title: 'My Profile',
                      onTap: () => context.push('/profile'),
                      showSeparator: false,
                    ),
                  ],
                ),
                GroupedSection(
                  title: 'Utility',
                  children: [
                    SettingsRow(
                      icon: const Icon(Icons.search),
                      iconBg: _neutralBg,
                      title: 'Search',
                      onTap: () => context.push('/search'),
                      showSeparator: false,
                    ),
                  ],
                ),
                GroupedSection(
                  title: 'System',
                  children: [
                    SettingsRow(
                      icon: const Icon(Icons.settings_outlined),
                      iconBg: _neutralBg,
                      title: 'Settings',
                      onTap: () => context.push('/settings'),
                    ),
                    if (DemoSession.instance.isAdmin)
                      SettingsRow(
                        icon: const Icon(CupertinoIcons.money_dollar_circle),
                        iconBg: const Color(0x26FF9500),
                        iconColor: const Color(0xFFFF9500),
                        title: 'Expense Management',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF9500).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Admin',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF9500))),
                        ),
                        onTap: () => context.push('/expenses'),
                      ),
                    if (StaffAccessStore.instance.canOpen('/administration'))
                      SettingsRow(
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        iconBg: _neutralBg,
                        title: 'Administration',
                        onTap: () => context.push('/administration'),
                        showSeparator: false,
                      ),
                    if (!DemoSession.instance.isAdmin)
                      SettingsRow(
                        icon: const Icon(Icons.shield_outlined),
                        iconBg: const Color(0x26007AFF),
                        iconColor: AppColors.brandLight,
                        title: 'My Access & Permissions',
                        onTap: () => context.push('/my-access'),
                        showSeparator: false,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '${AppConstants.appName} · Version ${AppConstants.appVersion} · ${AppConstants.appSubtitle}',
                    style: TextStyle(fontSize: 12, color: nec.textTertiary),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
