import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_toast.dart';
import 'widgets/set_password_form.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  Future<void> _handleSetPassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.length < 8) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Password must be at least 8 characters long.';
      });
      NecToast.show(
        context,
        message: 'Password must be at least 8 characters.',
        type: NecToastType.error,
      );
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Passwords do not match.';
      });
      NecToast.show(
        context,
        message: 'Passwords do not match.',
        type: NecToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasError = false;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    NecToast.show(
      context,
      message: 'Password reset successfully!',
      type: NecToastType.success,
    );

    context.go('/password-reset-success');
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
          child: SetPasswordForm(
            newPasswordController: _newPasswordController,
            confirmPasswordController: _confirmPasswordController,
            obscureNew: _obscureNew,
            obscureConfirm: _obscureConfirm,
            onToggleObscureNew: () =>
                setState(() => _obscureNew = !_obscureNew),
            onToggleObscureConfirm: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            onSubmit: _handleSetPassword,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            hasError: _hasError,
          ),
        ),
      ),
    );
  }
}
