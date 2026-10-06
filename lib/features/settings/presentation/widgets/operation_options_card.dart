import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/follow_up_visit_settings_store.dart';
import '../../domain/models/operation_option.dart';

class OperationOptionsCard extends StatelessWidget {
  final List<OperationOptionGroup> groups;
  final FollowUpVisitSettingsStore settings;
  final ValueChanged<OperationOptionGroup> onAdd;

  const OperationOptionsCard({
    super.key,
    required this.groups,
    required this.settings,
    required this.onAdd,
  });

  Future<bool> _confirmRemoval(
      BuildContext context, OperationOption option) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Remove ${option.name}?'),
            content: const Text(
                'Existing records using this option will be preserved.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final group in groups) ...[
            Container(
              height: 40,
              padding: const EdgeInsets.only(left: 16, right: 4),
              color: Color.lerp(nec.surface, nec.bg, 0.12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.title,
                      style: TextStyle(
                        color: nec.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Add ${group.singular.toLowerCase()}',
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: settings.ready ? () => onAdd(group) : null,
                      child:
                          Icon(CupertinoIcons.add, color: nec.brand, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            for (final option in settings.optionsFor(group)) ...[
              if (option.isSystem)
                _OptionRow(option: option)
              else
                Dismissible(
                  key: ValueKey('${group.name}:${option.name}'),
                  direction: settings.ready
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  confirmDismiss: (_) => _confirmRemoval(context, option),
                  onDismissed: (_) => settings.remove(group, option),
                  background: Container(
                    color: AppColors.error,
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  child: _OptionRow(
                    option: option,
                    onChanged: settings.ready
                        ? (value) => settings.toggle(group, option, value)
                        : null,
                  ),
                ),
              if (group != groups.last ||
                  option != settings.optionsFor(group).last)
                Divider(height: 1, thickness: 0.5, color: nec.separator),
            ],
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final OperationOption option;
  final ValueChanged<bool>? onChanged;

  const _OptionRow({required this.option, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Container(
      color: nec.surface,
      constraints: const BoxConstraints(minHeight: 49),
      padding: const EdgeInsets.only(left: 16, right: 8, top: 6, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  option.name,
                  style: TextStyle(fontSize: 15, color: nec.textPrimary),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: option.isSystem
                        ? nec.textTertiary.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    option.isSystem ? 'SYSTEM' : 'CUSTOM',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.5,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: option.isSystem
                          ? nec.textTertiary
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: option.isSystem
                ? '${option.name}, system option, always enabled'
                : option.name,
            child: Transform.scale(
              scale: 0.8,
              child: CupertinoSwitch(
                value: option.enabled,
                activeTrackColor: AppColors.success,
                onChanged: option.isSystem ? null : onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
