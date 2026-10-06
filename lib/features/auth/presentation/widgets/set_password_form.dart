import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import 'auth_field.dart';

class SetPasswordForm extends StatelessWidget {
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureNew;
  final bool obscureConfirm;
  final VoidCallback onToggleObscureNew;
  final VoidCallback onToggleObscureConfirm;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final bool hasError;

  const SetPasswordForm({
    super.key,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.onToggleObscureNew,
    required this.onToggleObscureConfirm,
    required this.onSubmit,
    required this.isLoading,
    this.errorMessage,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isValid = newPasswordController.text.trim().isNotEmpty &&
        confirmPasswordController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create new password',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: nec.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your new password must be at least 8 characters.',
          style: TextStyle(
            fontSize: 15,
            color: nec.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        AuthField(
          label: 'New Password',
          hintText: 'New password',
          controller: newPasswordController,
          obscureText: obscureNew,
          borderColor: hasError ? AppColors.error : null,
          suffixIcon: IconButton(
            icon: Icon(
              obscureNew
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: nec.textTertiary,
            ),
            onPressed: onToggleObscureNew,
          ),
        ),
        const SizedBox(height: 16),
        AuthField(
          label: 'Confirm Password',
          hintText: 'Confirm password',
          controller: confirmPasswordController,
          obscureText: obscureConfirm,
          borderColor: hasError ? AppColors.error : null,
          suffixIcon: IconButton(
            icon: Icon(
              obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: nec.textTertiary,
            ),
            onPressed: onToggleObscureConfirm,
          ),
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
          label: 'Set Password',
          onPressed: isValid ? onSubmit : null,
          fullWidth: true,
          loading: isLoading,
        ),
      ],
    );
  }
}
