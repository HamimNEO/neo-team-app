import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/audit_entry.dart';
import 'audit_high_badge.dart';
import 'audit_style.dart';

class AuditLogRow extends StatelessWidget {
  final AuditEntry entry;
  final VoidCallback onTap;

  const AuditLogRow({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: auditActorColor(entry.actor),
                shape: BoxShape.circle,
              ),
              child: Text(
                entry.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: auditCategoryColor(entry.category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        entry.action,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      if (entry.highImpact) const AuditHighBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.entity} · ${entry.entityType}',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      color: nec.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.actor} · ${auditTimestampLabel(entry.timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: nec.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 12,
                color: nec.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
