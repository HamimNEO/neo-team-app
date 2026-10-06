import 'package:flutter/material.dart';
import '../../../../core/widgets/nec_button.dart';
import 'employee_personal_fields.dart';
import 'employee_photo_field.dart';

class AddEmployeeStep1 extends StatelessWidget {
  final EmployeePersonalDraft draft;
  final GlobalKey<FormState> formKey;
  final VoidCallback onContinue;
  final VoidCallback onPhotoChanged;
  final ValueChanged<bool> onPhotoBusyChanged;
  final bool busy;

  const AddEmployeeStep1(
      {super.key,
      required this.draft,
      required this.formKey,
      required this.onContinue,
      required this.onPhotoChanged,
      required this.onPhotoBusyChanged,
      this.busy = false});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
            key: formKey,
            child: Column(children: [
              EmployeePhotoField(
                  name: draft.name.text,
                  photoBase64: draft.photo,
                  onBusyChanged: onPhotoBusyChanged,
                  onChanged: (photo) {
                    draft.photo = photo;
                    onPhotoChanged();
                  }),
              const SizedBox(height: 20),
              EmployeePersonalFields(draft: draft),
              const SizedBox(height: 24),
              NecButton(
                  label: 'Continue',
                  fullWidth: true,
                  onPressed: !busy &&
                          draft.name.text.trim().isNotEmpty &&
                          draft.email.text.trim().isNotEmpty
                      ? onContinue
                      : null),
              const SizedBox(height: 24),
            ])),
      );
}
