import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';

class LeadMoreTab extends StatelessWidget {
  final String leadId;

  const LeadMoreTab({
    super.key,
    required this.leadId,
  });

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onAdd,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: nec.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          if (onAdd != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onAdd,
              child: Text(
                '+ Add',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: nec.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'NOTES',
            onAdd: () {
              NecToast.show(
                context,
                message: 'Add note coming soon',
                type: NecToastType.info,
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Client wants a product demo after 4 PM. Seems genuinely interested in the enterprise package."',
                  style: TextStyle(
                    fontSize: 14,
                    color: nec.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Shahina Akter · Today 11:20 AM',
                  style: TextStyle(
                    fontSize: 12,
                    color: nec.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          _buildSectionHeader(
            context,
            'ATTACHMENTS',
            onAdd: () {
              NecToast.show(
                context,
                message: 'Add attachment coming soon',
                type: NecToastType.info,
              );
            },
          ),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.doc_fill,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              title: Text(
                'Blue_Wave_Requirements.pdf',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: nec.textPrimary,
                ),
              ),
              subtitle: Text(
                '245 KB · Shahina Akter · Today',
                style: TextStyle(fontSize: 12, color: nec.textTertiary),
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: nec.textTertiary,
              ),
              onTap: () {
                NecToast.show(
                  context,
                  message: 'Opening Blue_Wave_Requirements.pdf...',
                  type: NecToastType.info,
                );
              },
            ),
          ),
          _buildSectionHeader(context, 'ACTIONS'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: nec.brand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.pen,
                      color: nec.brand,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    'Edit Lead',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: () => context.push('/edit-lead/$leadId'),
                ),
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.2),
                  indent: 52,
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: nec.textTertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.clock,
                      color: nec.textTertiary,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    'Assignment History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    'Coming in full release',
                    style: TextStyle(fontSize: 11, color: nec.textTertiary),
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.2),
                  indent: 52,
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: nec.textTertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_right_arrow_left,
                      color: nec.textTertiary,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    'Status History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    'Coming in full release',
                    style: TextStyle(fontSize: 11, color: nec.textTertiary),
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
