import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class TaskSegmentSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;

  const TaskSegmentSelector({
    super.key,
    required this.selectedIndex,
    required this.onSegmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    const segments = AppConstants.taskSegments;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: segments.asMap().entries.map((entry) {
          final isSelected = selectedIndex == entry.key;
          final isLast = entry.key == segments.length - 1;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSegmentSelected(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(right: isLast ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? nec.brand : nec.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : nec.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
