import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../auth/domain/models/employee_login.dart';
import '../../auth/presentation/widgets/password_field.dart';
import '../../team/data/employee_store.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _actor = DemoSession.instance.employeeId;
  bool _saving = false;

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      if (!DemoSession.instance.signedIn ||
          DemoSession.instance.employeeId != _actor) {
        throw const FormatException('Sign in again to change your password.');
      }
      await EmployeeStore.instance
          .changePassword(_current.text, _password.text);
      if (!mounted) return;
      setState(() => _saving = false);
      NecToast.show(context, message: 'Password changed successfully');
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) context.popAppRoute(fallback: '/profile');
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: error is FormatException
                ? error.message
                : 'Unable to change your password. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: nec.bg,
        appBar: AppBar(
          backgroundColor: nec.bg,
          title: const Text('Change Password',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _saving
                  ? null
                  : () => context.popAppRoute(fallback: '/profile'),
              child: Icon(CupertinoIcons.back, color: nec.brand)),
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AbsorbPointer(
              absorbing: _saving,
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose your own password',
                          style: TextStyle(
                              color: nec.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                          DemoSession.instance.isAdmin
                              ? 'Use at least 8 characters to protect your administrator account.'
                              : 'Use at least 8 characters. Your administrator can manage your login password after verifying their own password.',
                          style: TextStyle(
                              color: nec.textSecondary,
                              fontSize: 14,
                              height: 1.4)),
                      const SizedBox(height: 24),
                      PasswordField(
                          label: 'Current Password',
                          controller: _current,
                          newPassword: false,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter your current password.'
                              : null),
                      PasswordField(
                          label: 'New Password',
                          controller: _password,
                          validator: (value) =>
                              EmployeeLogin.passwordError(value ?? '')),
                      PasswordField(
                          label: 'Confirm New Password',
                          controller: _confirm,
                          validator: (value) => value == _password.text &&
                                  (value?.isNotEmpty ?? false)
                              ? null
                              : 'Passwords do not match.'),
                      const SizedBox(height: 8),
                      NecButton(
                          label: 'Save Password',
                          fullWidth: true,
                          loading: _saving,
                          onPressed: _save),
                    ]),
              )),
        )),
      ),
    );
  }
}
