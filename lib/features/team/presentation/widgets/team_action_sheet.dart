import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import 'add_team_member_sheet.dart';

class TeamActionSheet extends StatelessWidget {
  final String teamName;

  const TeamActionSheet({
    super.key,
    required this.teamName,
  });

  void _openAddMemberSheet(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddTeamMemberSheet(teamName: teamName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

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
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                NecToast.show(
                  context,
                  message: 'Edit $teamName',
                  type: NecToastType.info,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Edit Team',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nec.brand,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                NecToast.show(
                  context,
                  message: 'Change Team Lead coming soon',
                  type: NecToastType.info,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Change Team Lead',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
            InkWell(
              onTap: () => _openAddMemberSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Add Member',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
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
