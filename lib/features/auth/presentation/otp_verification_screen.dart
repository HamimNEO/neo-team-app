import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_toast.dart';
import 'widgets/otp_verification_form.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      setState(() {
        if (_hasError) {
          _hasError = false;
          _errorMessage = null;
        }
      });
    });
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter the full 6-digit verification code.';
      });
      NecToast.show(
        context,
        message: 'Please enter the full 6-digit code.',
        type: NecToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage =
          'Verification is not available yet. Contact your administrator.';
    });
  }

  Future<void> _handleResendCode() async {
    NecToast.show(
      context,
      message:
          'Password reset is not available yet. Contact your administrator.',
      type: NecToastType.error,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: nec.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: nec.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 68),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: nec.separator.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: OtpVerificationForm(
            email: widget.email,
            codeController: _codeController,
            onVerify: _handleVerifyCode,
            onResend: _handleResendCode,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            hasError: _hasError,
          ),
        ),
      ),
    );
  }
}
