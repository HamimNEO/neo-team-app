import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_toast.dart';

class AddTeamMemberSheet extends StatelessWidget {
  final String teamName;
  final ValueChanged<String>? onMemberAdded;

  const AddTeamMemberSheet({
    super.key,
    required this.teamName,
    this.onMemberAdded,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final sheetHeight = MediaQuery.of(context).size.height * 0.68;

    final candidateEmployees = [
      {
        'name': 'Mahmud Hasan',
        'designation': 'General Manager',
        'initials': 'MH'
      },
      {
        'name': 'Md. Yeapas',
        'designation': 'Senior Software Engineer',
        'initials': 'MY'
      },
      {
        'name': 'Rashidul Islam',
        'designation': 'Sales Executive',
        'initials': 'RI'
      },
      {
        'name': 'MD. Abdul Hamim',
        'designation': 'Flutter Developer',
        'initials': 'MA'
      },
      {
        'name': 'Tania Rahman',
        'designation': 'Business Development Executive',
        'initials': 'TR'
      },
      {
        'name': 'Fahim Ahmed',
        'designation': 'Sales Coordinator',
        'initials': 'FA'
      },
      {
        'name': 'Karim Hossain',
        'designation': 'Senior Sales Manager',
        'initials': 'KH'
      },
      {'name': 'Anika Tasnim', 'designation': 'Support Lead', 'initials': 'AT'},
      {
        'name': 'Nusrat Jahan',
        'designation': 'Marketing Coordinator',
        'initials': 'NJ'
      },
      {
        'name': 'Tanvir Ahmed',
        'designation': 'DevOps Engineer',
        'initials': 'TA'
      },
    ];

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: nec.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add Team Member',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: nec.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(candidateEmployees.length, (index) {
                      final item = candidateEmployees[index];
                      final isLast = index == candidateEmployees.length - 1;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            leading: NecAvatar(
                              initials: item['initials']!,
                              size: 38,
                            ),
                            title: Text(
                              item['name']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: nec.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              item['designation']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              if (onMemberAdded != null) {
                                onMemberAdded!(item['name']!);
                              }
                              NecToast.show(
                                context,
                                message: 'Added ${item['name']} to $teamName',
                                type: NecToastType.success,
                              );
                            },
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: nec.separator.withValues(alpha: 0.2),
                              indent: 72,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
