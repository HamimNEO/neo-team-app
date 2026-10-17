import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../team/domain/models/employee.dart';

class HomeProfileAvatar extends StatelessWidget {
  const HomeProfileAvatar(
      {super.key, required this.employee, required this.administrator});

  final Employee employee;
  final bool administrator;

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final status = administrator ? 'Active' : employee.status;
    final isActive = status.toLowerCase() == 'active' || status.isEmpty;

    return Semantics(
      button: true,
      label: administrator ? 'Super Admin profile' : '${employee.name} profile',
      child: SizedBox(
        width: 54,
        height: 54,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF8A52F3),
                    Color(0xFFC782FE),
                    Color(0xFF5582FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: nec.surface,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(1.5),
                child: administrator
                    ? ClipOval(
                        child: Image.asset(
                          AppConstants.superAdminAvatarAsset,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      )
                    : NecAvatar(
                        initials: employee.avatarInitials,
                        photoBase64: employee.photoBase64,
                        photoUrl: employee.photoUrl,
                        assetPath: employee.avatarAsset,
                        size: 44,
                      ),
              ),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                  border: Border.all(color: nec.bg, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
