import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import 'auth_field.dart';

class ForgotPasswordForm extends StatelessWidget {
  final TextEditingController emailController;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMessage;

  const ForgotPasswordForm({
    super.key,
    required this.emailController,
    required this.onSubmit,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isValid = emailController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: nec.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your work email and we'll send you a reset link.",
          style: TextStyle(
            fontSize: 15,
            color: nec.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        AuthField(
          label: 'Work Email',
          hintText: 'you@neonecy.com',
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 28),
        NecButton(
          label: 'Continue',
          onPressed: isValid ? onSubmit : null,
          fullWidth: true,
          loading: isLoading,
        ),
      ],
    );
  }
}
