import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/models/module_info.dart';

class ModuleManagerScreen extends StatefulWidget {
  const ModuleManagerScreen({super.key});

  @override
  State<ModuleManagerScreen> createState() => _ModuleManagerScreenState();
}

class _ModuleManagerScreenState extends State<ModuleManagerScreen> {
  late List<ModuleInfo> _modules;

  @override
  void initState() {
    super.initState();
    _modules = [
      ModuleInfo(
        id: 'mod_leads',
        name: 'Leads',
        description: 'Lead management and CRM operations',
        category: 'CORE',
        isRequired: true,
        isEnabled: true,
        icon: CupertinoIcons.person_2_fill,
        iconColor: AppColors.brandLight,
      ),
      ModuleInfo(
        id: 'mod_team',
        name: 'Team',
        description: 'Employee directory and organization structure',
        category: 'CORE',
        isRequired: true,
        isEnabled: true,
        icon: CupertinoIcons.person_3_fill,
        iconColor: const Color(0xFF5856D6),
      ),
      ModuleInfo(
        id: 'mod_tasks',
        name: 'Tasks',
        description: 'Task management and work tracking',
        category: 'CORE',
        isRequired: false,
        isEnabled: true,
        icon: CupertinoIcons.checkmark_square_fill,
        iconColor: const Color(0xFF5856D6),
      ),
      ModuleInfo(
        id: 'mod_followups',
        name: 'Follow-ups',
        description: 'Lead follow-up operations and scheduling',
        category: 'OPERATIONS',
        isRequired: false,
        isEnabled: true,
        icon: CupertinoIcons.arrow_right_arrow_left,
        iconColor: const Color(0xFFFF9500),
      ),
      ModuleInfo(
        id: 'mod_visits',
        name: 'Visits',
        description: 'Visit scheduling and field operations',
        category: 'OPERATIONS',
        isRequired: false,
        isEnabled: true,
        icon: CupertinoIcons.house_fill,
        iconColor: const Color(0xFFFF9500),
      ),
      ModuleInfo(
        id: 'mod_issues',
        name: 'Issues',
        description: 'Bug reports and customer support tracking',
        category: 'OPERATIONS',
        isRequired: false,
        isEnabled: true,
        icon: CupertinoIcons.exclamationmark_circle_fill,
        iconColor: AppColors.error,
      ),
      ModuleInfo(
        id: 'mod_activity',
        name: 'Activity',
        description: 'Cross-module activity timeline',
        category: 'SYSTEM',
        isRequired: true,
        isEnabled: true,
        icon: CupertinoIcons.waveform_path_ecg,
        iconColor: const Color(0xFF30B0C7),
      ),
      ModuleInfo(
        id: 'mod_notifications',
        name: 'Notifications',
        description: 'In-app notification system',
        category: 'SYSTEM',
        isRequired: true,
        isEnabled: true,
        icon: CupertinoIcons.bell_fill,
        iconColor: AppColors.brandLight,
      ),
      ModuleInfo(
        id: 'mod_search',
        name: 'Search',
        description: 'Global search across all modules',
        category: 'SYSTEM',
        isRequired: false,
        isEnabled: true,
        icon: CupertinoIcons.search,
        iconColor: const Color(0xFF8E8E93),
      ),
    ];
  }

  void _showRequiredModuleSheet(ModuleInfo module) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final nec = Theme.of(context).extension<NecColors>()!;
        return Material(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: nec.textTertiary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: module.iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          module.icon,
                          color: module.iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: nec.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    module.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: nec.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: nec.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: nec.separator.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.lock_fill,
                          color: nec.textTertiary,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This is a required module and cannot be disabled.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: nec.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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

    final coreModules = _modules.where((m) => m.category == 'CORE').toList();
    final opsModules =
        _modules.where((m) => m.category == 'OPERATIONS').toList();
    final systemModules =
        _modules.where((m) => m.category == 'SYSTEM').toList();

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
                  'Module Manager',
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
              Text(
                'Control which features are available across NEC TEAM. Required modules cannot be disabled.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: nec.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(nec, 'CORE'),
              _buildModuleGroupCard(nec, coreModules),
              const SizedBox(height: 24),
              _buildSectionHeader(nec, 'OPERATIONS'),
              _buildModuleGroupCard(nec, opsModules),
              const SizedBox(height: 24),
              _buildSectionHeader(nec, 'SYSTEM'),
              _buildModuleGroupCard(nec, systemModules),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Disabling a module removes it from navigation but preserves all data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: nec.textTertiary,
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

  Widget _buildModuleGroupCard(NecColors nec, List<ModuleInfo> modules) {
    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(modules.length, (index) {
          final mod = modules[index];
          final isLast = index == modules.length - 1;

          return Column(
            children: [
              InkWell(
                onTap:
                    mod.isRequired ? () => _showRequiredModuleSheet(mod) : null,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: mod.iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          mod.icon,
                          color: mod.iconColor,
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
                                Text(
                                  mod.name,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: nec.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: mod.isRequired
                                        ? AppColors.success
                                            .withValues(alpha: 0.15)
                                        : AppColors.brandLight
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    mod.isRequired ? 'Required' : 'Enabled',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: mod.isRequired
                                          ? AppColors.success
                                          : AppColors.brandLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mod.description,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: nec.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mod.isRequired)
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.lock_fill,
                            size: 18,
                            color: nec.textTertiary,
                          ),
                          onPressed: () => _showRequiredModuleSheet(mod),
                        )
                      else
                        Switch.adaptive(
                          value: mod.isEnabled,
                          activeTrackColor: AppColors.success,
                          onChanged: (val) {
                            setState(() {
                              mod.isEnabled = val;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.2),
                  indent: 68,
                ),
            ],
          );
        }),
      ),
    );
  }
}
