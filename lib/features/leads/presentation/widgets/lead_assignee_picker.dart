import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../team/data/employee_store.dart';
import 'add_lead_picker_sheet.dart';

Future<String?> chooseLeadAssignee(
    BuildContext context, String? employeeId) async {
  if (!DemoSession.instance.isAdmin) return null;
  String? selected;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => AddLeadPickerSheet(
      title: 'Assigned Employee',
      options: [
        const {'label': 'Unassigned', 'value': ''},
        for (final employee in EmployeeStore.instance.employees
            .where((employee) => employee.status == 'Active'))
          {
            'label': employee.name,
            'value': employee.id,
            'subtitle': employee.designation
          },
      ],
      selectedValue: employeeId ?? '',
      onSelected: (value) => selected = value as String,
    ),
  );
  return selected;
}
