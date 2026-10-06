import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class AppPermissionsScreen extends StatefulWidget {
  const AppPermissionsScreen({super.key});

  @override
  State<AppPermissionsScreen> createState() => _AppPermissionsScreenState();
}

class _AppPermissionsScreenState extends State<AppPermissionsScreen>
    with WidgetsBindingObserver {
  Map<AppPermissionType, PermissionStatusInfo> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissions();
    }
  }

  Future<void> _loadPermissions() async {
    final perms = await PermissionService.instance.checkAllPermissions();
    if (mounted) {
      setState(() {
        _permissions = perms;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleToggle(PermissionStatusInfo info) async {
    if (info.isGranted) {
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Disable ${info.title}'),
          content: Text(
            'To disable ${info.title}, toggle it off in your device System Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Open Settings',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        await PermissionService.instance.openNativeSettings();
      }
    } else {
      await PermissionService.instance.requestOrToggle(info.permission);
      await _loadPermissions();
    }
  }

  IconData _getIconForType(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.location:
        return CupertinoIcons.location_fill;
      case AppPermissionType.camera:
        return CupertinoIcons.camera_fill;
      case AppPermissionType.gallery:
        return CupertinoIcons.photo_fill_on_rectangle_fill;
      case AppPermissionType.files:
        return CupertinoIcons.folder_fill;
      case AppPermissionType.notification:
        return CupertinoIcons.bell_fill;
    }
  }

  Color _getColorForType(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.location:
        return AppColors.brandLight;
      case AppPermissionType.camera:
        return AppColors.warning;
      case AppPermissionType.gallery:
        return AppColors.success;
      case AppPermissionType.files:
        return AppColors.leadContacted;
      case AppPermissionType.notification:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

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
                      'Settings',
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
                  'App Permissions',
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
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            CupertinoIcons.shield_lefthalf_fill,
                            color: nec.brand,
                            size: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Native Device Permissions',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: nec.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'NEC TEAM requests native permissions for field visits, attachments, and real-time updates. You can toggle them directly here or via your device settings.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: nec.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'PERMISSIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: nec.textTertiary,
                        ),
                      ),
                    ),
                    Material(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: _permissions.values.map((info) {
                          final isLast = info == _permissions.values.last;
                          final icon = _getIconForType(info.type);
                          final color = _getColorForType(info.type);

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 20,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  info.title,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: nec.textPrimary,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: info.isGranted
                                                      ? AppColors.success
                                                          .withValues(
                                                              alpha: 0.15)
                                                      : nec.separator
                                                          .withValues(
                                                              alpha: 0.25),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  info.isGranted
                                                      ? 'Allowed'
                                                      : 'Off',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: info.isGranted
                                                        ? AppColors.success
                                                        : nec.textTertiary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            info.subtitle,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: nec.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Switch.adaptive(
                                      value: info.isGranted,
                                      activeTrackColor: AppColors.success,
                                      onChanged: (_) => _handleToggle(info),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: 70,
                                  color: nec.separator.withValues(alpha: 0.2),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            PermissionService.instance.openNativeSettings(),
                        icon: const Icon(CupertinoIcons.gear_alt, size: 18),
                        label: const Text(
                          'Open Device Settings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: nec.brand,
                          side: BorderSide(
                            color: nec.brand.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}
