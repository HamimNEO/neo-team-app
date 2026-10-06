import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import 'home_theme_toggle.dart';
import '../../../team/data/employee_store.dart';

class HomeGreetingBar extends StatelessWidget {
  final String greeting;
  final String userName;
  final String userInitials;
  final String dateString;

  const HomeGreetingBar({
    super.key,
    this.greeting = 'Good afternoon,',
    required this.userName,
    required this.userInitials,
    required this.dateString,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return AnimatedBuilder(
        animation: EmployeeStore.instance,
        builder: (context, _) {
          final employee = EmployeeStore.instance.currentEmployee;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        greeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: nec.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee.name
                                .split(RegExp(r'\s+'))
                                .where((part) =>
                                    !['Most.', 'Md.', 'MD.'].contains(part))
                                .firstOrNull ??
                            employee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: nec.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const HomeThemeToggle(),
                    const SizedBox(width: 4),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () => context.push('/notifications'),
                          icon: Icon(
                            CupertinoIcons.bell,
                            color: nec.textPrimary,
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: nec.surface,
                            shape: const CircleBorder(),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: NecAvatar(
                          initials: employee.avatarInitials,
                          photoBase64: employee.photoBase64,
                          size: 38),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }
}
