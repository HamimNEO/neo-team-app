import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class LeadFilterBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;

  const LeadFilterBar({
    super.key,
    required this.selectedIndex,
    required this.onSegmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    const segments = AppConstants.leadFilterSegments;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: segments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSegmentSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? nec.brand : nec.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                segments[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : nec.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
