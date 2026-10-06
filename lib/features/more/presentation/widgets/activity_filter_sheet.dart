import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ActivityFilterSheet extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const ActivityFilterSheet({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final filterOptions = [
      'All Activity',
      'My Activity',
      'Leads',
      'Follow-ups',
      'Visits',
      'Tasks',
      'Issues',
      'Team & Admin',
    ];

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
              'Filter Activity',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(filterOptions.length, (index) {
                    final option = filterOptions[index];
                    final isSelected = selectedFilter == option;
                    final isLast = index == filterOptions.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 2,
                          ),
                          title: Text(
                            option,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected ? nec.brand : nec.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  CupertinoIcons.checkmark,
                                  color: nec.brand,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            onFilterSelected(option);
                            Navigator.pop(context);
                          },
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.2),
                            indent: 20,
                          ),
                      ],
                    );
                  }),
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
