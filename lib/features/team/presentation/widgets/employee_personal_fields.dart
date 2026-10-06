import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/employee.dart';
import 'employee_form_field.dart';

class EmployeePersonalDraft {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final dateOfBirth = TextEditingController();
  final emergencyName = TextEditingController();
  final emergencyPhone = TextEditingController();
  String? photo;

  EmployeePersonalDraft([Employee? employee]) {
    if (employee == null) return;
    name.text = employee.name;
    email.text = employee.email;
    phone.text = employee.phone;
    address.text = employee.address;
    dateOfBirth.text = employee.dateOfBirth;
    emergencyName.text = employee.emergencyContactName;
    emergencyPhone.text = employee.emergencyContactPhone;
    photo = employee.photoBase64;
  }

  void dispose() {
    for (final controller in [
      name,
      email,
      phone,
      address,
      dateOfBirth,
      emergencyName,
      emergencyPhone
    ]) {
      controller.dispose();
    }
  }
}

class EmployeePersonalFields extends StatelessWidget {
  final EmployeePersonalDraft draft;
  final bool selfEdit;

  const EmployeePersonalFields(
      {super.key, required this.draft, this.selfEdit = false});

  Future<void> _pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(draft.dateOfBirth.text) ??
            DateTime(now.year - 25),
        firstDate: DateTime(1900),
        lastDate: now);
    if (context.mounted && date != null) {
      draft.dateOfBirth.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        EmployeeFormField(
            label: 'Full Name *',
            controller: draft.name,
            hint: 'e.g. Hamim Leon',
            validator: requiredEmployeeField),
        EmployeeFormField(
            label: selfEdit ? 'Work Email (managed by admin)' : 'Work Email *',
            controller: draft.email,
            hint: 'you@neonecy.com',
            readOnly: selfEdit,
            keyboardType: TextInputType.emailAddress,
            validator: employeeEmailValidator),
        EmployeeFormField(
            label: 'Phone',
            controller: draft.phone,
            hint: '+880 1700-000000',
            keyboardType: TextInputType.phone,
            validator: employeePhoneValidator),
        ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Personal & emergency information',
                style: TextStyle(fontSize: 14)),
            initiallyExpanded: selfEdit,
            maintainState: true,
            children: [
              EmployeeFormField(
                  label: 'Date of Birth',
                  controller: draft.dateOfBirth,
                  hint: 'Select date',
                  readOnly: true,
                  onTap: () => _pickBirthday(context)),
              EmployeeFormField(
                  label: 'Address',
                  controller: draft.address,
                  hint: 'Present address',
                  maxLines: 2),
              EmployeeFormField(
                  label: 'Emergency Contact Name',
                  controller: draft.emergencyName),
              EmployeeFormField(
                  label: 'Emergency Contact Phone',
                  controller: draft.emergencyPhone,
                  keyboardType: TextInputType.phone,
                  validator: employeePhoneValidator),
            ]),
      ]);
}
