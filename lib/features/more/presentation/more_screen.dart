import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/settings_row.dart';
import '../../../core/services/staff_access_store.dart';
import '../../messages/data/message_store.dart';
import '../../messages/data/group_chat_store.dart';
import '../../team/data/employee_store.dart';

import '../../certificates/data/certificate_store.dart';
import '../data/more_store.dart';
import '../data/notification_store.dart';
import 'widgets/workspace_hero_card.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    MoreStore.instance.load();
    NotificationStore.instance.load();
    CertificateStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    CertificateStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return AnimatedBuilder(
      animation: Listenable.merge([
        MoreStore.instance,
        NotificationStore.instance,
        StaffAccessStore.instance,
        DemoSession.instance,
      ]),
      builder: (context, _) {
        final store = MoreStore.instance;
        final unreadNotif = NotificationStore.instance.hasLoaded
            ? NotificationStore.instance.unreadCount
            : store.unreadNotificationsCount;

        return Scaffold(
          backgroundColor: nec.bg,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 2),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: nec.separator.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              SliverAppBar(
                pinned: true,
                backgroundColor: nec.bg,
                centerTitle: true,
                title: Text(
                  'More',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: nec.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WorkspaceHeroCard(),
                    GroupedSection(
                      title: 'Work',
                      children: [
                        if (StaffAccessStore.instance.canOpen('/meals'))
                          SettingsRow(
                            icon: const Icon(CupertinoIcons.cart),
                            iconBg: const Color(0x2622A447),
                            iconColor: const Color(0xFF22A447),
                            title: DemoSession.instance.isAdmin
                                ? 'Lunch Management'
                                : 'My Office Lunch',
                            onTap: () => context.push(
                                DemoSession.instance.isAdmin
                                    ? '/meals/admin'
                                    : '/meals'),
                          ),
                        if (StaffAccessStore.instance.canOpen('/attendance'))
                          SettingsRow(
                            icon: const Icon(CupertinoIcons.clock),
                            iconBg: const Color(0x26007AFF),
                            iconColor: AppColors.brandLight,
                            title: DemoSession.instance.isAdmin
                                ? 'Attendance Management'
                                : 'My Attendance',
                            onTap: () => context.push(
                                DemoSession.instance.isAdmin
                                     ? '/attendance/admin'
                                    : '/attendance'),
                          ),
                        SettingsRow(
                          icon: const Icon(CupertinoIcons.doc_checkmark),
                          iconBg: const Color(0x266366F1),
                          iconColor: const Color(0xFF6366F1),
                          title: DemoSession.instance.isAdmin
                              ? 'Certificate & Testimonials'
                              : 'My Certificate Requests',
                          trailing: CertificateStore.instance.pendingCount > 0 &&
                                  DemoSession.instance.isAdmin
                              ? _buildBadge(
                                  CertificateStore.instance.pendingCount,
                                  AppColors.warning)
                              : null,
                          onTap: () => context.push(
                              DemoSession.instance.isAdmin
                                  ? '/certificates/admin'
                                  : '/certificates/my'),
                        ),
                        if (StaffAccessStore.instance.canOpen('/follow-ups'))
                          SettingsRow(
                            icon: const Icon(Icons.reply_outlined),
                            iconBg: const Color(0x26E39B08),
                            iconColor: const Color(0xFFE39B08),
                            title: 'Follow-ups',
                            trailing: store.followupsToday > 0
                                ? _buildBadge(
                                    store.followupsToday, AppColors.warning)
                                : null,
                            onTap: () => context.push('/follow-ups'),
                          ),
                        if (StaffAccessStore.instance.canOpen('/visits'))
                          SettingsRow(
                            icon: const Icon(Icons.home_work_outlined),
                            iconBg: const Color(0x26FF6B35),
                            iconColor: const Color(0xFFFF6B35),
                            title: 'Visits',
                            trailing: store.visitsCount > 0
                                ? _buildBadge(
                                    store.visitsCount, AppColors.leadVisit)
                                : null,
                            onTap: () => context.push('/visits'),
                          ),
                        if (StaffAccessStore.instance.canOpen('/issues'))
                          SettingsRow(
                            icon: const Icon(Icons.report_outlined),
                            iconBg: const Color(0x26E5484D),
                            iconColor: const Color(0xFFE5484D),
                            title: 'Issues',
                            trailing: store.issuesCount > 0
                                ? _buildBadge(
                                    store.issuesCount, AppColors.error)
                                : null,
                            onTap: () => context.push('/issues'),
                          ),
                        if (StaffAccessStore.instance.canOpen('/team'))
                          SettingsRow(
                            icon: const Icon(Icons.group_outlined),
                            iconBg: const Color(0x267952E8),
                            iconColor: const Color(0xFF7952E8),
                            title: 'Team',
                            trailing: store.teamMembersCount > 0
                                ? _buildBadge(store.teamMembersCount,
                                    AppColors.brandLight)
                                : null,
                            onTap: () => context.push('/team'),
                          ),
                        if (StaffAccessStore.instance.canOpen('/activity'))
                          SettingsRow(
                            icon: const Icon(Icons.timeline_outlined),
                            iconBg: const Color(0x2614A69C),
                            iconColor: const Color(0xFF14A69C),
                            title: 'Activity',
                            trailing: store.recentActivityCount > 0
                                ? _buildBadge(store.recentActivityCount,
                                    AppColors.brandLight)
                                : null,
                            onTap: () => context.push('/activity'),
                            showSeparator: false,
                          ),
                      ],
                    ),
                    GroupedSection(
                      title: 'Personal',
                      children: [
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            MessageStore.instance,
                            GroupChatStore.instance,
                            DemoSession.instance,
                            EmployeeStore.instance,
                          ]),
                          builder: (context, _) {
                            final unread = MessageStore.instance.unreadCount +
                                GroupChatStore.instance.unreadCount;
                            return SettingsRow(
                              icon:
                                  const Icon(CupertinoIcons.chat_bubble_2_fill),
                              iconBg: const Color(0x2612AFCB),
                              iconColor: const Color(0xFF12AFCB),
                              title: 'Messages',
                              subtitle: 'Chat with staff and admins',
                              trailing: unread == 0
                                  ? null
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: nec.brand,
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Text(
                                          unread > 99 ? '99+' : '$unread',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                              onTap: () => context.push('/messages'),
                            );
                          },
                        ),
                        SettingsRow(
                          icon: const Icon(Icons.notifications_outlined),
                          iconBg: const Color(0x26E55293),
                          iconColor: const Color(0xFFE55293),
                          title: 'Notifications',
                          trailing: unreadNotif > 0
                              ? _buildBadge(unreadNotif, AppColors.error)
                              : null,
                          onTap: () => context.push('/notifications'),
                        ),
                        SettingsRow(
                          icon: const Icon(Icons.person_outline),
                          iconBg: const Color(0x265364D9),
                          iconColor: const Color(0xFF5364D9),
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
                          iconBg: const Color(0x263D8DD9),
                          iconColor: const Color(0xFF3D8DD9),
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
                          iconBg: const Color(0x26647BC0),
                          iconColor: const Color(0xFF647BC0),
                          title: 'Settings',
                          onTap: () => context.push('/settings'),
                        ),
                        if (DemoSession.instance.isAdmin)
                          SettingsRow(
                            icon:
                                const Icon(CupertinoIcons.money_dollar_circle),
                            iconBg: const Color(0x26FF9500),
                            iconColor: const Color(0xFFFF9500),
                            title: 'Expense Management',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9500)
                                    .withValues(alpha: 0.15),
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
                        if (StaffAccessStore.instance
                            .canOpen('/administration'))
                          SettingsRow(
                            icon:
                                const Icon(Icons.admin_panel_settings_outlined),
                            iconBg: const Color(0x269B4DD9),
                            iconColor: const Color(0xFF9B4DD9),
                            title: 'Administration',
                            onTap: () => context.push('/administration'),
                            showSeparator: false,
                          ),
                        if (!DemoSession.instance.isAdmin)
                          SettingsRow(
                            icon: const Icon(Icons.shield_outlined),
                            iconBg: const Color(0x26199776),
                            iconColor: const Color(0xFF199776),
                            title: 'My Access & Permissions',
                            onTap: () => context.push('/my-access'),
                            showSeparator: false,
                          ),
                      ],
                    ),
                    GroupedSection(
                      title: 'Information & Support',
                      children: [
                        SettingsRow(
                          icon: const Icon(CupertinoIcons.shield_fill),
                          iconBg: const Color(0x263478F6),
                          iconColor: const Color(0xFF3478F6),
                          title: 'Privacy Policy',
                          subtitle: 'Data handling & user privacy',
                          onTap: () => context.push('/policy/privacy-policy'),
                        ),
                        SettingsRow(
                          icon: const Icon(CupertinoIcons.doc_text_fill),
                          iconBg: const Color(0x266750B9),
                          iconColor: const Color(0xFF6750B9),
                          title: 'Terms & Conditions',
                          subtitle: 'Usage terms & service rules',
                          onTap: () =>
                              context.push('/policy/terms-and-conditions'),
                        ),
                        SettingsRow(
                          icon: const Icon(CupertinoIcons.trash_fill),
                          iconBg: const Color(0x26D8435B),
                          iconColor: const Color(0xFFD8435B),
                          title: 'Account & Data Deletion',
                          subtitle: 'Delete account & stored data',
                          onTap: () => context.push('/policy/data-deletion'),
                        ),
                        SettingsRow(
                          icon: const Icon(CupertinoIcons.chart_pie_fill),
                          iconBg: const Color(0x2629A879),
                          iconColor: const Color(0xFF29A879),
                          title: 'Data Collection',
                          subtitle: 'Collected data & permissions',
                          onTap: () => context.push('/policy/data-collection'),
                        ),
                        SettingsRow(
                          icon: const Icon(CupertinoIcons.chat_bubble_2_fill),
                          iconBg: const Color(0x26F58B20),
                          iconColor: const Color(0xFFF58B20),
                          title: 'Support & Contact',
                          subtitle: 'Help desk & direct support',
                          onTap: () => context.push('/policy/support'),
                        ),
                        SettingsRow(
                          icon: const Icon(CupertinoIcons.globe),
                          iconBg: const Color(0x26239DB1),
                          iconColor: const Color(0xFF239DB1),
                          title: 'Company Website',
                          subtitle: 'Visit neonecy.com',
                          trailing: const Icon(CupertinoIcons.arrow_up_right,
                              size: 14),
                          onTap: () async {
                            final uri = Uri.parse('https://neonecy.com/');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
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
      },
    );
  }
}
