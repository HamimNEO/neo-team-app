import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class SessionSection extends StatelessWidget {
  const SessionSection({super.key});

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of NEC TEAM?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await DemoSession.instance.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (_) {
                if (context.mounted) {
                  NecToast.show(context,
                      message: 'Unable to sign out. Please try again.',
                      type: NecToastType.error);
                }
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
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
            'Account lifecycle is managed by your organization\nadministrator.',
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
