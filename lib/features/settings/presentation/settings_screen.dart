import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/app_haptics.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/widgets/sign_out_dialog.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_alert_manager.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

import '../data/user_settings_store.dart';
import 'widgets/notification_tone_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    UserSettingsStore.instance.load();
  }

  void _confirmSignOut(BuildContext context) => confirmAndSignOut(context);

  void _showDefaultViewPicker(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final current = UserSettingsStore.instance.defaultView.toLowerCase();

    final options = [
      (
        key: 'home',
        title: 'Home',
        subtitle: 'Overview metrics, shortcuts & recent leads',
        icon: CupertinoIcons.house_fill,
      ),
      (
        key: 'leads',
        title: 'Leads',
        subtitle: 'Pipeline, statuses, stages & lead directory',
        icon: CupertinoIcons.person_2_fill,
      ),
      (
        key: 'tasks',
        title: 'Tasks',
        subtitle: 'My tasks, team assignments & deadlines',
        icon: CupertinoIcons.checkmark_circle_fill,
      ),
      (
        key: 'messages',
        title: 'Messages',
        subtitle: 'Staff team chats, direct conversations & groups',
        icon: CupertinoIcons.chat_bubble_2_fill,
      ),
      (
        key: 'attendance',
        title: 'Attendance',
        subtitle: 'Punch clock, attendance history & status',
        icon: CupertinoIcons.clock_fill,
      ),
      (
        key: 'more',
        title: 'More',
        subtitle: 'Company tools, meals, leaves & operations',
        icon: CupertinoIcons.square_grid_2x2_fill,
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.68,
          child: Material(
            color: nec.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: nec.textTertiary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Default Landing View',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 24,
                            color: nec.textTertiary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select which view loads automatically on app launch and sign in.',
                        style: TextStyle(
                          fontSize: 13,
                          color: nec.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                      height: 1, color: nec.separator.withValues(alpha: 0.25)),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 52,
                        color: nec.separator.withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, index) {
                        final opt = options[index];
                        final isSelected = opt.key == current;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            AppHaptics.selectionClick();
                            Navigator.of(sheetContext).pop();
                            UserSettingsStore.instance
                                .updateSettings(defaultView: opt.key);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Default view set to ${opt.title}'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? nec.brand.withValues(alpha: 0.15)
                                        : nec.bg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    opt.icon,
                                    size: 20,
                                    color: isSelected
                                        ? nec.brand
                                        : nec.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        opt.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: nec.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        opt.subtitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: nec.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    CupertinoIcons.checkmark_alt_circle_fill,
                                    size: 22,
                                    color: nec.brand,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  'Settings',
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
              _buildSectionHeader(nec, 'ACCOUNT'),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      onTap: () => context.push('/profile'),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    ListTile(
                      title: Text(
                        'Account & Security',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      onTap: () => context.push('/account-security'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(nec, 'APP'),
              ListenableBuilder(
                listenable: UserSettingsStore.instance,
                builder: (context, _) {
                  final settingsStore = UserSettingsStore.instance;
                  return Material(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            isDark
                                ? 'Dark appearance active'
                                : 'Light appearance active (Default)',
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textTertiary,
                            ),
                          ),
                          trailing: CupertinoSwitch(
                            value: isDark,
                            activeTrackColor: nec.brand,
                            onChanged: (val) {
                              AppHaptics.selectionClick();
                              context.read<ThemeProvider>().toggleDarkMode(val);
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                          indent: 16,
                        ),
                        ListTile(
                          title: Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.watch<ThemeProvider>().styleTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: nec.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: nec.textTertiary,
                              ),
                            ],
                          ),
                          onTap: () => context.push('/appearance'),
                        ),
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                          indent: 16,
                        ),
                        ListTile(
                          title: Text(
                            'Language',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'English',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: nec.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: nec.textTertiary,
                              ),
                            ],
                          ),
                          onTap: () {},
                        ),
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                          indent: 16,
                        ),
                        ListTile(
                          title: Text(
                            'Default View',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                settingsStore.defaultViewTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: nec.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: nec.textTertiary,
                              ),
                            ],
                          ),
                          onTap: () => _showDefaultViewPicker(context),
                        ),
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                          indent: 16,
                        ),
                        ListTile(
                          title: Text(
                            'Haptic Feedback',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Subtle feedback for supported actions',
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textTertiary,
                            ),
                          ),
                          trailing: CupertinoSwitch(
                            value: settingsStore.hapticFeedback,
                            activeTrackColor: AppColors.success,
                            onChanged: (val) {
                              settingsStore.updateSettings(hapticFeedback: val);
                              if (val) {
                                HapticFeedback.mediumImpact();
                              }
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                          indent: 16,
                        ),
                        ListTile(
                          title: Text(
                            'Reduce Motion',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Reduce interface motion effects',
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textTertiary,
                            ),
                          ),
                          trailing: CupertinoSwitch(
                            value: settingsStore.reduceMotion,
                            activeTrackColor: AppColors.success,
                            onChanged: (val) {
                              settingsStore.updateSettings(reduceMotion: val);
                              AppHaptics.lightImpact();
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                          indent: 16,
                        ),
                        ListTile(
                          title: Text(
                            'Device Permissions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Location, Camera, Gallery, Files, Alerts',
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
                          onTap: () => context.push('/permissions'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(nec, 'NOTIFICATIONS'),
              ListenableBuilder(
                listenable: NotificationAlertManager.instance,
                builder: (context, _) {
                  final alertMgr = NotificationAlertManager.instance;
                  return Material(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            'Notification Sound',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            alertMgr.soundEnabled
                                ? 'Tone enabled (${alertMgr.selectedTone.title})'
                                : 'Notification sound muted',
                            style: TextStyle(
                                fontSize: 12, color: nec.textTertiary),
                          ),
                          trailing: CupertinoSwitch(
                            value: alertMgr.soundEnabled,
                            activeTrackColor: nec.brand,
                            onChanged: (val) {
                              alertMgr.setSoundEnabled(val);
                              if (val) {
                                alertMgr.triggerAlert(forceSound: true);
                              }
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          indent: 16,
                          color: nec.separator.withValues(alpha: 0.3),
                        ),
                        ListTile(
                          title: Text(
                            'Notification Tone',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: alertMgr.soundEnabled
                                  ? nec.textPrimary
                                  : nec.textTertiary,
                            ),
                          ),
                          subtitle: Text(
                            alertMgr.soundEnabled
                                ? alertMgr.selectedTone.subtitle
                                : 'Sound is currently muted',
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textTertiary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                alertMgr.selectedTone.title.split(' (').first,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: alertMgr.soundEnabled
                                      ? nec.textTertiary
                                      : nec.textTertiary.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: alertMgr.soundEnabled
                                    ? nec.textTertiary
                                    : nec.textTertiary.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                          onTap: alertMgr.soundEnabled
                              ? () => NotificationToneSheet.show(context)
                              : null,
                        ),
                        Divider(
                          height: 1,
                          indent: 16,
                          color: nec.separator.withValues(alpha: 0.3),
                        ),
                        ListTile(
                          title: Text(
                            'Vibrate with Sound',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            alertMgr.vibrationEnabled
                                ? 'Vibrate on incoming notifications'
                                : 'Vibration turned off',
                            style: TextStyle(
                                fontSize: 12, color: nec.textTertiary),
                          ),
                          trailing: CupertinoSwitch(
                            value: alertMgr.vibrationEnabled,
                            activeTrackColor: nec.brand,
                            onChanged: (val) {
                              alertMgr.setVibrationEnabled(val);
                              if (val) {
                                alertMgr.triggerAlert(forceVibration: true);
                              }
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          indent: 16,
                          color: nec.separator.withValues(alpha: 0.3),
                        ),
                        ListTile(
                          title: Text(
                            'Notification Preferences',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                          trailing: Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: nec.textTertiary,
                          ),
                          onTap: () =>
                              context.push('/notification-preferences'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(nec, 'ACCESS'),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(
                    'Role & Permissions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: () => context.push(DemoSession.instance.isAdmin
                      ? '/role-permissions'
                      : '/my-access'),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(nec, 'SYSTEM'),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(
                    'About NEC TEAM',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'v${AppConstants.appVersion}',
                        style: TextStyle(
                          fontSize: 15,
                          color: nec.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                    ],
                  ),
                  onTap: () => context.push('/about'),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(nec, 'LEGAL & POLICIES'),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        CupertinoIcons.shield_fill,
                        color: nec.brand,
                        size: 20,
                      ),
                      title: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      onTap: () => context.push('/policy/privacy-policy'),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 52,
                    ),
                    ListTile(
                      leading: const Icon(
                        CupertinoIcons.doc_text_fill,
                        color: Color(0xFF5856D6),
                        size: 20,
                      ),
                      title: Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      onTap: () => context.push('/policy/terms-and-conditions'),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 52,
                    ),
                    ListTile(
                      leading: const Icon(
                        CupertinoIcons.trash_fill,
                        color: Color(0xFFFF3B30),
                        size: 20,
                      ),
                      title: Text(
                        'Account & Data Deletion',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      onTap: () => context.push('/policy/data-deletion'),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 52,
                    ),
                    ListTile(
                      leading: const Icon(
                        CupertinoIcons.chart_pie_fill,
                        color: Color(0xFF34C759),
                        size: 20,
                      ),
                      title: Text(
                        'Data Collection',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      onTap: () => context.push('/policy/data-collection'),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 52,
                    ),
                    ListTile(
                      leading: const Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        color: Color(0xFFFF9500),
                        size: 20,
                      ),
                      title: Text(
                        'Support & Contact',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      onTap: () => context.push('/policy/support'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _confirmSignOut(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
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
