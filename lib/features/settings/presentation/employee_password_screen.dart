import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../auth/domain/models/employee_login.dart';
import '../../auth/presentation/widgets/password_field.dart';
import '../../team/data/employee_store.dart';
import 'widgets/admin_password_prompt.dart';

class EmployeePasswordScreen extends StatefulWidget {
  final String employeeId;

  const EmployeePasswordScreen({super.key, required this.employeeId});

  @override
  State<EmployeePasswordScreen> createState() => _EmployeePasswordScreenState();
}

class _EmployeePasswordScreenState extends State<EmployeePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController(text: '••••••••');
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _actor = DemoSession.instance.employeeId;
  bool _saving = false;
  int _revision = 0;

  bool get _authorized =>
      DemoSession.instance.signedIn &&
      DemoSession.instance.isAdmin &&
      DemoSession.instance.employeeId == _actor &&
      EmployeeStore.instance.isStaffEmployee(widget.employeeId);

  @override
  void initState() {
    super.initState();
    EmployeeStore.instance.addListener(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    _current.text = '••••••••';
    setState(() => _revision++);
  }

  void _showError(Object error) {
    if (mounted) {
      NecToast.show(context,
          message: error is FormatException
              ? error.message.toString()
              : 'Unable to manage this password. Please try again.',
          type: NecToastType.error);
    }
  }

  Future<bool> _verifyReveal() async {
    if (!_authorized) return false;
    final password = await requestAdminPassword(context);
    return mounted && _authorized && password != null;
  }

  Future<bool> _revealCurrent() async {
    if (!_authorized) return false;
    final adminPassword = await requestAdminPassword(context);
    if (!mounted || !_authorized || adminPassword == null) return false;
    try {
      final password = await EmployeeStore.instance
          .revealEmployeePassword(widget.employeeId, adminPassword);
      if (!mounted || !_authorized) return false;
      if (password == null) {
        throw const FormatException(
            'The previous password isn’t available. Set a new password for this employee.');
      }
      _current.text = password;
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<void> _save() async {
    if (_saving || !_authorized || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final adminPassword = await requestAdminPassword(context);
      if (!mounted || !_authorized || adminPassword == null) return;
      await EmployeeStore.instance.resetEmployeePassword(
          widget.employeeId, _password.text, adminPassword);
      if (!mounted) return;
      _password.clear();
      _confirm.clear();
      _current.text = '••••••••';
      setState(() => _saving = false);
      NecToast.show(context, message: 'Employee password updated');
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) {
        context.popAppRoute(fallback: '/employee/${widget.employeeId}');
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    EmployeeStore.instance.removeListener(_refresh);
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final employee = EmployeeStore.instance.byId(widget.employeeId);
    return PopScope(
        canPop: !_saving,
        child: Scaffold(
          backgroundColor: nec.bg,
          appBar: AppBar(
              backgroundColor: nec.bg,
              title: const Text('Employee Password',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _saving
                      ? null
                      : () => context.popAppRoute(fallback: '/team'),
                  child: Icon(CupertinoIcons.back, color: nec.brand))),
          body: !_authorized || employee == null
              ? const Center(
                  child: Text(
                      'Administrator access to a staff account is required.'))
              : SafeArea(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: AbsorbPointer(
                          absorbing: _saving,
                          child: Form(
                              key: _form,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      NecAvatar(
                                          initials: employee.avatarInitials,
                                          photoBase64: employee.photoBase64,
                                          size: 48),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(employee.name,
                                                style: TextStyle(
                                                    color: nec.textPrimary,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            const SizedBox(height: 4),
                                            Text(
                                                EmployeeStore.instance
                                                    .loginEmailFor(employee.id),
                                                style: TextStyle(
                                                    color: nec.textSecondary,
                                                    fontSize: 13)),
                                          ])),
                                    ]),
                                    const SizedBox(height: 24),
                                    Text('Manage Login Password',
                                        style: TextStyle(
                                            color: nec.textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Verify your admin password each time you reveal a password or save a change. Revealed passwords hide after 30 seconds. The employee can change their password from My Profile.',
                                        style: TextStyle(
                                            color: nec.textSecondary,
                                            fontSize: 14,
                                            height: 1.5)),
                                    const SizedBox(height: 24),
                                    PasswordField(
                                        key: ValueKey(_revision),
                                        label: 'Current Employee Password',
                                        controller: _current,
                                        readOnly: true,
                                        newPassword: false,
                                        validator: (_) => null,
                                        onReveal: _revealCurrent,
                                        onHidden: () =>
                                            _current.text = '••••••••'),
                                    PasswordField(
                                        label: 'New Password',
                                        controller: _password,
                                        validator: (value) =>
                                            EmployeeLogin.passwordError(
                                                value ?? ''),
                                        onReveal: _verifyReveal),
                                    PasswordField(
                                        label: 'Confirm New Password',
                                        controller: _confirm,
                                        validator: (value) =>
                                            value == _password.text &&
                                                    (value?.isNotEmpty ?? false)
                                                ? null
                                                : 'Passwords do not match.',
                                        onReveal: _verifyReveal),
                                    const SizedBox(height: 8),
                                    NecButton(
                                        label: 'Save Employee Password',
                                        fullWidth: true,
                                        loading: _saving,
                                        onPressed: _save),
                                  ]))))),
        ));
  }
}
