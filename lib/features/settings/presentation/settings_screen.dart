import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticFeedback = true;
  bool _reduceMotion = false;

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of NEC TEAM?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await DemoSession.instance.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (_) {
                if (context.mounted) {
                  NecToast.show(context,
                      message: 'Unable to sign out. Please try again.',
                      type: NecToastType.error);
                }
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
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
                            isDark ? 'Dark' : 'Light',
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
                            'Home',
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
                    SwitchListTile.adaptive(
                      value: _hapticFeedback,
                      onChanged: (val) {
                        setState(() {
                          _hapticFeedback = val;
                        });
                      },
                      activeTrackColor: AppColors.success,
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
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    SwitchListTile.adaptive(
                      value: _reduceMotion,
                      onChanged: (val) {
                        setState(() {
                          _reduceMotion = val;
                        });
                      },
                      activeTrackColor: AppColors.success,
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
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(nec, 'NOTIFICATIONS'),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
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
                  onTap: () => context.push('/notification-preferences'),
                ),
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
