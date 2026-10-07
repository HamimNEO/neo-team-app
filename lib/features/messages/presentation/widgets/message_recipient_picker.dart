import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../team/data/employee_store.dart';

Future<String?> chooseMessageRecipient(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MessageRecipientPicker(),
    );

class _MessageRecipientPicker extends StatefulWidget {
  const _MessageRecipientPicker();

  @override
  State<_MessageRecipientPicker> createState() =>
      _MessageRecipientPickerState();
}

class _MessageRecipientPickerState extends State<_MessageRecipientPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: EmployeeStore.instance,
        builder: (context, _) {
          final nec = Theme.of(context).extension<NecColors>()!;
          final people = EmployeeStore.instance.employees
              .where((employee) =>
                  employee.id != DemoSession.instance.employeeId &&
                  '${employee.name} ${employee.email} ${employee.department} ${employee.systemRole}'
                      .toLowerCase()
                      .contains(_query.toLowerCase().trim()))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return Material(
            color: nec.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .82,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: SafeArea(
                    top: false,
                    child: Column(children: [
                      const SizedBox(height: 10),
                      Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: nec.textTertiary.withValues(alpha: .4),
                              borderRadius: BorderRadius.circular(4))),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                          child: Row(children: [
                            Expanded(
                                child: Text('New Message',
                                    style: TextStyle(
                                        color: nec.textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700))),
                            CupertinoButton(
                                onPressed: () => Navigator.pop(context),
                                child: Icon(CupertinoIcons.xmark_circle_fill,
                                    color: nec.textTertiary)),
                          ])),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: CupertinoSearchTextField(
                            placeholder: 'Search staff or admins',
                            backgroundColor: nec.bg,
                            style: TextStyle(color: nec.textPrimary),
                            placeholderStyle:
                                TextStyle(color: nec.textTertiary),
                            onChanged: (query) =>
                                setState(() => _query = query),
                          )),
                      Expanded(
                          child: people.isEmpty
                              ? Center(
                                  child: Text('No matching people',
                                      style:
                                          TextStyle(color: nec.textSecondary)))
                              : ListView.separated(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  itemCount: people.length,
                                  separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      indent: 80,
                                      color: nec.separator),
                                  itemBuilder: (context, index) {
                                    final employee = people[index];
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 5),
                                      leading: NecAvatar(
                                          initials: employee.avatarInitials,
                                          photoBase64: employee.photoBase64,
                                          size: 46),
                                      title: Text(employee.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: nec.textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                      subtitle: Text(
                                          '${employee.designation}\n${employee.systemRole}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: nec.textSecondary,
                                              fontSize: 12,
                                              height: 1.5)),
                                      trailing: Icon(CupertinoIcons.chat_bubble,
                                          color: nec.brand, size: 20),
                                      onTap: () =>
                                          Navigator.pop(context, employee.id),
                                    );
                                  },
                                )),
                    ])),
              ),
            ),
          );
        },
      );
}
