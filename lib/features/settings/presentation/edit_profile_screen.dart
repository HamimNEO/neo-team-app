import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../team/data/employee_store.dart';
import '../../team/presentation/widgets/employee_personal_fields.dart';
import '../../team/presentation/widgets/employee_photo_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final EmployeePersonalDraft _draft;
  late final String _ownerId;
  late final bool _administrator;
  bool _saving = false;
  bool _saved = false;
  bool _photoBusy = false;

  @override
  void initState() {
    super.initState();
    _ownerId = DemoSession.instance.employeeId;
    _administrator = DemoSession.instance.isAdmin;
    _draft = EmployeePersonalDraft(EmployeeStore.instance.currentEmployee);
    _draft.name.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_saving ||
        _photoBusy ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (!DemoSession.instance.signedIn ||
          DemoSession.instance.employeeId != _ownerId) {
        throw const FormatException(
            'Your account changed. Reopen Edit Profile to continue.');
      }
      final current = EmployeeStore.instance.byId(_ownerId);
      if (current == null) {
        throw const FormatException('This account is no longer available.');
      }
      final employee = current.editPersonalDetails(
        name: _draft.name.text.trim(),
        phone: _draft.phone.text.trim(),
        address: _draft.address.text.trim(),
        dateOfBirth: _draft.dateOfBirth.text,
        emergencyContactName: _draft.emergencyName.text.trim(),
        emergencyContactPhone: _draft.emergencyPhone.text.trim(),
        photoBase64: _draft.photo,
      );
      await EmployeeStore.instance.save(employee);
      if (!mounted) return;
      NecToast.show(context, message: 'Profile updated successfully');
      setState(() => _saved = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: error is FormatException
                ? error.message.toString()
                : 'Unable to save your profile. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return PopScope(
        canPop: _saved || !_saving,
        child: Scaffold(
          backgroundColor: nec.bg,
          appBar: AppBar(
              backgroundColor: nec.bg,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              leadingWidth: 90,
              leading: CupertinoButton(
                  padding: const EdgeInsets.only(left: 16),
                  onPressed: _saving ? null : () => context.pop(),
                  child: Row(children: [
                    Icon(CupertinoIcons.back, color: nec.brand, size: 18),
                    Text(' Back',
                        style: TextStyle(color: nec.brand, fontSize: 16))
                  ])),
              title: Text(
                  _administrator ? 'Edit Admin Profile' : 'Edit Profile',
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(height: 1, color: nec.separator))),
          body: SafeArea(
            child: AbsorbPointer(
                absorbing: _saving,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                      key: _formKey,
                      child: Column(children: [
                        EmployeePhotoField(
                            name: _draft.name.text,
                            photoBase64: _draft.photo,
                            onChanged: (photo) =>
                                setState(() => _draft.photo = photo),
                            onBusyChanged: (busy) =>
                                setState(() => _photoBusy = busy)),
                        const SizedBox(height: 20),
                        EmployeePersonalFields(
                            draft: _draft,
                            selfEdit: true,
                            administrator: _administrator),
                        const SizedBox(height: 12),
                        Text(
                            _administrator
                                ? 'Update your photo, name and contact details here. Organization settings and staff access are available in Administration.'
                                : 'Employment, work email, role, and salary changes are managed by your administrator.',
                            style: TextStyle(
                                color: nec.textTertiary,
                                fontSize: 12,
                                height: 1.5)),
                        const SizedBox(height: 24),
                        NecButton(
                            label: 'Save Changes',
                            fullWidth: true,
                            loading: _saving,
                            onPressed: _saving || _photoBusy ? null : _save),
                      ])),
                )),
          ),
        ));
  }
}
