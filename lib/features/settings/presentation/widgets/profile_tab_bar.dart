import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<String> tabs;

  const ProfileTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.tabs = const ['Overview', 'My Work', 'Activity', 'More'],
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: nec.separator.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? nec.brand : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? nec.brand : nec.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
