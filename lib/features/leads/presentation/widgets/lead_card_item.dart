import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';

import '../../../../core/widgets/nec_badge.dart';

class LeadCardItem extends StatelessWidget {
  final String company;
  final String subtitle;
  final String status;
  final Color? statusColor;
  final String? scheduleNote;
  final bool isOverdue;
  final String assigneeInitials;
  final String assigneeName;
  final String? photoBase64, photoUrl, avatarAsset;
  final String? phone;
  final VoidCallback? onCall;
  final VoidCallback onTap;

  const LeadCardItem({
    super.key,
    required this.company,
    required this.subtitle,
    required this.status,
    this.statusColor,
    this.scheduleNote,
    this.isOverdue = false,
    required this.assigneeInitials,
    required this.assigneeName,
    this.photoBase64,
    this.photoUrl,
    this.avatarAsset,
    this.phone,
    this.onCall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    company,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                LeadStatusBadge(status: status, small: true),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: nec.textTertiary,
              ),
            ),
            if (scheduleNote != null && scheduleNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              LeadStatusBadge(
                status: isOverdue ? '$scheduleNote · Overdue' : scheduleNote!,
                small: true,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (assigneeInitials != '??')
                  NecAvatar(
                    initials: assigneeInitials,
                    photoBase64: photoBase64,
                    photoUrl: photoUrl,
                    assetPath: avatarAsset,
                    size: 22,
                  )
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: nec.textTertiary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.person,
                      size: 12,
                      color: nec.textTertiary,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assigneeName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: nec.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (phone != null && phone!.trim().isNotEmpty && onCall != null)
                  GestureDetector(
                    onTap: onCall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.phone_fill,
                            size: 12,
                            color: Color(0xFF34C759),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Call',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF34C759),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
