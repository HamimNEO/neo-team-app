import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/widgets/sign_out_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class SessionSection extends StatelessWidget {
  const SessionSection({super.key});

  void _confirmSignOut(BuildContext context) => confirmAndSignOut(context);

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(
            'SESSION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: nec.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Material(
          color: nec.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _confirmSignOut(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'Sign Out',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            DemoSession.instance.isAdmin
                ? 'You manage organization settings and staff access.'
                : 'Account lifecycle is managed by your organization\nadministrator.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: nec.textTertiary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
