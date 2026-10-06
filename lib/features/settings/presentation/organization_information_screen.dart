import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/system_settings_store.dart';
import 'widgets/operations_settings_app_bar.dart';

class OrganizationInformationScreen extends StatefulWidget {
  const OrganizationInformationScreen({super.key});

  @override
  State<OrganizationInformationScreen> createState() =>
      _OrganizationInformationScreenState();
}

class _OrganizationInformationScreenState
    extends State<OrganizationInformationScreen> {
  final _settings = SystemSettingsStore.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    await _settings.load();
    if (!mounted) return;
    _nameController.text = _settings.value.organizationName;
    _emailController.text = _settings.value.primaryWorkEmail;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_loaded || _saving || !_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    final saved = await _settings.update((settings) => settings.copyWith(
          organizationName: _nameController.text.trim(),
          primaryWorkEmail: _emailController.text.trim(),
        ));
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) {
      NecToast.show(
        context,
        message: 'Could not save organization details. Please try again.',
        type: NecToastType.error,
      );
      return;
    }
    NecToast.show(context, message: 'Organization information saved');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/system-settings');
    }
  }

  Widget _label(NecColors nec, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: nec.textTertiary,
          ),
        ),
      );

  InputDecoration _decoration(NecColors nec) => InputDecoration(
        filled: true,
        fillColor: nec.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: nec.separator.withValues(alpha: 0.4)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: nec.separator.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: nec.brand),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Scaffold(
      backgroundColor: nec.bg,
      appBar: const OperationsSettingsAppBar(
        title: 'Organization Information',
        fallbackPath: '/system-settings',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _label(nec, 'ORGANIZATION NAME'),
            TextFormField(
              controller: _nameController,
              enabled: _loaded && !_saving,
              style: TextStyle(fontSize: 16, color: nec.textPrimary),
              decoration: _decoration(nec),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.organizationName],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Enter an organization name';
                if (name.length > 100) return 'Use 100 characters or fewer';
                return null;
              },
            ),
            const SizedBox(height: 18),
            _label(nec, 'PRIMARY WORK EMAIL'),
            TextFormField(
              controller: _emailController,
              enabled: _loaded && !_saving,
              style: TextStyle(fontSize: 16, color: nec.textPrimary),
              decoration: _decoration(nec),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _save(),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Enter a valid work email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: nec.brand,
                disabledColor: nec.brand.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(26),
                onPressed: _loaded && !_saving ? _save : null,
                child: _saving
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
