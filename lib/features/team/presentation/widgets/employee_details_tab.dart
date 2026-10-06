import 'package:flutter/material.dart';
import '../../domain/models/employee.dart';
import '../../data/employee_store.dart';
import 'employee_details_section.dart';

class EmployeeDetailsTab extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailsTab({super.key, required this.employee});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(children: [
        EmployeeDetailsSection(title: 'Employment', rows: [
          ('Employee ID', employee.displayCode),
          ('Designation', employee.designation),
          ('Status', employee.status),
          ('Joined', employee.joinedDate),
          ('System Role', employee.systemRole),
          ('Department', employee.department.split(' · ').first),
          ('Team', employee.team),
          (
            'Reports To',
            EmployeeStore.instance.byId(employee.reportsToId ?? '')?.name ??
                employee.reportsTo ??
                'Not assigned'
          ),
        ]),
        EmployeeDetailsSection(title: 'Benefits & Schemes', rows: [
          (
            'Meal Policy',
            employee.isMealFree
                ? '100% Free (৳${(employee.totalMealCost / 100).toStringAsFixed(0)} / mo Sponsored)'
                : '${employee.mealCoPayPercent}% Co-Pay (৳${(employee.mealEmployeePayAmount / 100).toStringAsFixed(0)} / mo Cut From Salary)'
          ),
          (
            'Rotational Reserve',
            employee.hasRotationalReserve
                ? '৳${(employee.rotationalReserveAmount / 100).toStringAsFixed(0)} / month · December Payout'
                : 'Not enrolled'
          ),
        ]),
        EmployeeDetailsSection(title: 'Contact', rows: [
          ('Work Email', employee.email),
          ('Phone', employee.phone),
          ('Address', employee.address),
        ]),
        EmployeeDetailsSection(title: 'Personal information', rows: [
          ('Full Name', employee.name),
          ('Date of Birth', employee.dateOfBirth),
        ]),
        EmployeeDetailsSection(title: 'Emergency contact', rows: [
          ('Name', employee.emergencyContactName),
          ('Phone', employee.emergencyContactPhone),
        ]),
      ]));
}
