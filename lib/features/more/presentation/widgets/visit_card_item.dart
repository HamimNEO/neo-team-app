import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../domain/models/visit.dart';

class VisitCardItem extends StatelessWidget {
  final Visit visit;
  final VoidCallback onTap;

  const VisitCardItem({
    super.key,
    required this.visit,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'arrived':
        return const Color(0xFFAF52DE);
      case 'report due':
      case 'report':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return const Color(0xFF8E8E93);
      case 'scheduled':
      default:
        return AppColors.brandLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final statusColor = _getStatusColor(visit.status);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.timeText.split(' ')[0],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: nec.textPrimary,
                    ),
                  ),
                  Text(
                    visit.timeText.contains(' ')
                        ? visit.timeText.split(' ')[1]
                        : '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: nec.textTertiary,
                    ),
                  ),
                  if (visit.dateText != 'Today' &&
                      visit.dateText != 'Yesterday') ...[
                    const SizedBox(height: 2),
                    Text(
                      visit.dateText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: nec.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.leadName,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 12,
                        color: nec.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          visit.location,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: nec.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    visit.purpose,
                    style: TextStyle(
                      fontSize: 13,
                      color: nec.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      NecAvatar(
                        initials: visit.assigneeInitials,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        visit.assigneeName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: nec.textTertiary,
                        ),
                      ),
                      if (visit.resultTag != null) ...[
                        Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                        Text(
                          visit.resultTag!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: visit.resultTag == 'Interested'
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                visit.status == 'Report Due' ? 'REPORT' : visit.status,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
