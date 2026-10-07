import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../../team/data/employee_store.dart';

Future<String?> requestAdminPassword(BuildContext context) =>
    showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _AdminPasswordPrompt());

class _AdminPasswordPrompt extends StatefulWidget {
  const _AdminPasswordPrompt();

  @override
  State<_AdminPasswordPrompt> createState() => _AdminPasswordPromptState();
}

class _AdminPasswordPromptState extends State<_AdminPasswordPrompt> {
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _actor = DemoSession.instance.employeeId;
  bool _busy = false;
  bool _returning = false;
  String? _error;

  Future<void> _verify() async {
    if (_busy || _returning || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final password = _password.text;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await EmployeeStore.instance
          .verifyAdminPassword(password, actorId: _actor);
      if (mounted) {
        setState(() {
          _busy = false;
          _returning = true;
        });
        await WidgetsBinding.instance.endOfFrame;
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop(password);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message.toString()
            : 'Unable to verify your password.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: AlertDialog(
          title: const Text('Verify Admin Password'),
          content: SingleChildScrollView(
              child: Form(
                  key: _form,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            'Enter your own password to manage this employee’s login credentials.'),
                        const SizedBox(height: 16),
                        PasswordField(
                            label: 'Admin Password',
                            controller: _password,
                            newPassword: false,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your admin password.'
                                : null),
                        if (_error != null)
                          Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                      ]))),
          actions: [
            TextButton(
                onPressed: _busy || _returning
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            TextButton(
                onPressed: _busy || _returning ? null : _verify,
                child: Text(_busy ? 'Verifying…' : 'Verify')),
          ],
        ),
      );
}
