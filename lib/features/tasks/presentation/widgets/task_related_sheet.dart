import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class TaskRelatedSheet extends StatelessWidget {
  final String selectedRelated;
  final ValueChanged<String> onSelected;

  const TaskRelatedSheet({
    super.key,
    required this.selectedRelated,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final options = ['Lead', 'Issue', 'Internal', 'Client'];

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: nec.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Related To',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
            Column(
              children: List.generate(options.length, (index) {
                final opt = options[index];
                final isSelected = selectedRelated == opt;

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        onSelected(opt);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? nec.brand : nec.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                    ),
                  ],
                );
              }),
            ),
            InkWell(
              onTap: () {
                onSelected('None');
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Clear',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
