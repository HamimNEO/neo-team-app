import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../data/department_store.dart';
import '../../domain/models/department.dart';

class CreateDepartmentSheet extends StatefulWidget {
  const CreateDepartmentSheet({super.key, this.department});

  final DepartmentItem? department;

  @override
  State<CreateDepartmentSheet> createState() => _CreateDepartmentSheetState();
}

class _CreateDepartmentSheetState extends State<CreateDepartmentSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nameController, _codeController;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.department?.name);
    _codeController = TextEditingController(text: widget.department?.code);
    _active = widget.department?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await DepartmentStore.instance.save(
          department: widget.department,
          name: _nameController.text,
          code: _codeController.text,
          active: _active);
      if (mounted) Navigator.pop(context, result);
    } catch (exception) {
      if (mounted) {
        setState(() => _error = DepartmentStore.messageFor(exception));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(NecColors nec, bool dark, String label, String hint,
          TextEditingController controller) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
                color: dark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: nec.separator.withValues(alpha: 0.2))),
            child: TextFormField(
              controller: controller,
              enabled: !_saving,
              textCapitalization: controller == _codeController
                  ? TextCapitalization.characters
                  : TextCapitalization.words,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: nec.textPrimary),
              decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 15, color: nec.textTertiary)),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'This field is required.'
                  : null,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !_saving,
      child: Material(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
            child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: nec.textTertiary.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 12),
                  Center(
                      child: Text(
                          widget.department == null
                              ? 'Create Department'
                              : 'Edit Department',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: nec.textPrimary))),
                  const SizedBox(height: 16),
                  Divider(
                      height: 1, color: nec.separator.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  _field(nec, dark, 'DEPARTMENT NAME *', 'e.g. Operations',
                      _nameController),
                  const SizedBox(height: 20),
                  _field(nec, dark, 'DEPARTMENT CODE *', 'e.g. OPS',
                      _codeController),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: Text('Active',
                            style: TextStyle(
                                fontSize: 15, color: nec.textPrimary))),
                    CupertinoSwitch(
                        value: _active,
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _active = value)),
                  ]),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  const SizedBox(height: 20),
                  NecButton(
                      label: widget.department == null
                          ? 'Create Department'
                          : 'Save Changes',
                      fullWidth: true,
                      loading: _saving,
                      onPressed: _submit),
                ],
              )),
        )),
      ),
    );
  }
}
