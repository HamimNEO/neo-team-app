import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import 'auth_field.dart';

class OtpVerificationForm extends StatelessWidget {
  final String email;
  final TextEditingController codeController;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final bool isLoading;
  final String? errorMessage;
  final bool hasError;

  const OtpVerificationForm({
    super.key,
    required this.email,
    required this.codeController,
    required this.onVerify,
    required this.onResend,
    required this.isLoading,
    this.errorMessage,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final boxBorderColor = hasError
        ? AppColors.error
        : (codeController.text.isNotEmpty ? nec.brand : nec.separator);
    final isValid = codeController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check your email',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: nec.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            text: 'We sent a 6-digit code to ',
            style: TextStyle(
              fontSize: 15,
              color: nec.textSecondary,
              height: 1.4,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(
                text: email.isNotEmpty ? email : 'your email',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: nec.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return Container(
              width: 48,
              height: 56,
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: boxBorderColor,
                  width: (index < codeController.text.length || hasError)
                      ? 1.5
                      : 1,
                ),
              ),
              child: Center(
                child: Text(
                  index < codeController.text.length
                      ? codeController.text[index]
                      : '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        AuthField(
          label: 'Enter code',
          hintText: '123456',
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          borderColor: hasError ? AppColors.error : null,
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
          label: 'Verify Code',
          onPressed: isValid ? onVerify : null,
          fullWidth: true,
          loading: isLoading,
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: onResend,
            child: Text(
              'Resend code',
              style: TextStyle(
                color: nec.brand,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
