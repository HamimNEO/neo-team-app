import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/operations_settings_app_bar.dart';

class OperationsSettingsScreen extends StatelessWidget {
  const OperationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: const OperationsSettingsAppBar(title: 'Operations Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text(
            'Configure operational options for each module. Changes affect '
            "what’s available to employees in their daily workflows.",
            style:
                TextStyle(fontSize: 14, height: 1.45, color: nec.textSecondary),
          ),
          const SizedBox(height: 16),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingsLink(
                  title: 'Follow-up & Visit Settings',
                  subtitle: 'Methods, results, visit purposes and outcomes',
                  onTap: () => context.push('/follow-up-visit-settings'),
                ),
                Divider(height: 1, thickness: 0.5, color: nec.separator),
                _SettingsLink(
                  title: 'Task Settings',
                  subtitle: 'Workflow stages, priorities, task types',
                  onTap: () => context.push('/task-settings'),
                ),
                Divider(height: 1, thickness: 0.5, color: nec.separator),
                _SettingsLink(
                  title: 'Issue Settings',
                  subtitle: 'Categories, resolution types, workflow stages',
                  onTap: () => context.push('/issue-settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'System-defined items cannot be disabled. Custom items can be '
            'toggled or removed. Historical records are always preserved.',
            style:
                TextStyle(fontSize: 12, height: 1.5, color: nec.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsLink(
      {required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 16, color: nec.textPrimary),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: nec.textTertiary),
        ),
      ),
      trailing:
          Icon(CupertinoIcons.chevron_right, size: 14, color: nec.textTertiary),
      onTap: onTap,
    );
  }
}
