import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/department_store.dart';

Future<void> openDepartmentByName(BuildContext context, String name) async {
  final store = DepartmentStore.instance;
  await store.load();
  if (!context.mounted) return;
  final matching = store.departments.where((d) =>
      d.name.toLowerCase() == name.split(' · ').first.trim().toLowerCase());
  if (matching.isNotEmpty) {
    context.push('/department/${matching.first.id}');
  } else {
    NecToast.show(context,
        message:
            store.error ?? 'This employee has no matching backend department.',
        type: NecToastType.info);
  }
}
