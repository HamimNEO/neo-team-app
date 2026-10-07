import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../team/domain/models/employee.dart';
import '../../data/system_settings_store.dart';

class ProfileHeader extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEditTap;
  final bool administrator;

  const ProfileHeader(
      {super.key,
      required this.employee,
      required this.onEditTap,
      this.administrator = false});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(children: [
          Semantics(
              button: true,
              label: 'Edit profile photo',
              child: GestureDetector(
                  onTap: onEditTap,
                  child: Stack(children: [
                    NecAvatar(
                        initials: employee.avatarInitials,
                        photoBase64: employee.photoBase64,
                        backgroundColor: nec.brand,
                        size: 84),
                    Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: nec.brand,
                                shape: BoxShape.circle,
                                border: Border.all(color: nec.bg, width: 2)),
                            child: const Icon(CupertinoIcons.pencil,
                                size: 14, color: Colors.white))),
                  ]))),
          const SizedBox(height: 14),
          Text(employee.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: nec.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(employee.designation,
              textAlign: TextAlign.center,
              style: TextStyle(color: nec.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
              administrator
                  ? SystemSettingsStore.instance.value.organizationName
                  : employee.displayCode,
              style: TextStyle(color: nec.textTertiary, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Text(employee.status,
                    style: TextStyle(
                        color: employee.status == 'Active'
                            ? CupertinoColors.systemGreen
                            : nec.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text(
                    administrator
                        ? 'Administrator · Full access'
                        : '${employee.department.split(' · ').first} · ${employee.team}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: nec.textSecondary, fontSize: 13)),
              ]),
          Wrap(alignment: WrapAlignment.center, spacing: 24, children: [
            CupertinoButton(
                padding: const EdgeInsets.only(top: 12),
                onPressed: onEditTap,
                child: Text('Edit Profile',
                    style: TextStyle(color: nec.brand, fontSize: 14))),
            CupertinoButton(
              padding: const EdgeInsets.only(top: 12),
              onPressed: () => context.push('/messages'),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(CupertinoIcons.chat_bubble_fill,
                    color: nec.brand, size: 16),
                const SizedBox(width: 6),
                Text('Messages',
                    style: TextStyle(color: nec.brand, fontSize: 14)),
              ]),
            ),
          ]),
        ]));
  }
}
