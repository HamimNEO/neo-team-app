import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';

class ForgotPasswordSuccess extends StatelessWidget {
  final String email;
  final VoidCallback onBackToSignIn;

  const ForgotPasswordSuccess({
    super.key,
    required this.email,
    required this.onBackToSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: nec.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent a password reset link to\n$email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: nec.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        NecButton(
          label: 'Back to Sign In',
          onPressed: onBackToSignIn,
          fullWidth: true,
        ),
      ],
    );
  }
}
