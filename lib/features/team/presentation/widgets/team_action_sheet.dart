import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TeamActionSheet extends StatelessWidget {
  const TeamActionSheet(
      {super.key,
      required this.teamName,
      required this.onAddMember,
      this.onDelete,
      this.onEdit});

  final String teamName;
  final VoidCallback onAddMember;
  final VoidCallback? onDelete, onEdit;

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Material(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: nec.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
              title: const Text('Edit Team'),
              enabled: onEdit != null,
              onTap: onEdit == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      onEdit!();
                    }),
          Divider(height: 1, color: nec.separator),
          ListTile(
              title: const Text('Change Team Lead'),
              enabled: onEdit != null,
              onTap: onEdit == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      onEdit!();
                    }),
          Divider(height: 1, color: nec.separator),
          ListTile(
              title: const Text('Add Member'),
              onTap: () {
                Navigator.pop(context);
                onAddMember();
              }),
          if (onDelete != null) ...[
            Divider(height: 1, color: nec.separator),
            ListTile(
                title: const Text('Delete Team',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                }),
          ],
          const SizedBox(height: 12),
        ])));
  }
}
