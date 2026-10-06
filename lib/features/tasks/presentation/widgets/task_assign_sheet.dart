import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';

class TaskAssignSheet extends StatelessWidget {
  final String selectedAssignee;
  final ValueChanged<String> onSelected;

  const TaskAssignSheet({
    super.key,
    required this.selectedAssignee,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final sheetHeight = MediaQuery.of(context).size.height * 0.65;

    final candidates = [
      {'name': 'Unassigned', 'designation': '', 'initials': '??'},
      {
        'name': 'Mahmud Hasan',
        'designation': 'General Manager',
        'initials': 'MH'
      },
      {
        'name': 'Most. Shahina Akter',
        'designation': 'Digital Marketing Executive',
        'initials': 'MS'
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
        'designation': 'Sales Executive',
        'initials': 'TR'
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
                'Assign To',
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
                    children: List.generate(candidates.length, (index) {
                      final item = candidates[index];
                      final name = item['name']!;
                      final desig = item['designation']!;
                      final initials = item['initials']!;
                      final isSelected = selectedAssignee == name;
                      final isLast = index == candidates.length - 1;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            leading: initials == '??'
                                ? Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: nec.textTertiary
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.minus,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  )
                                : NecAvatar(
                                    initials: initials,
                                    size: 38,
                                  ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected ? nec.brand : nec.textPrimary,
                              ),
                            ),
                            subtitle: desig.isNotEmpty
                                ? Text(
                                    desig,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: nec.textTertiary,
                                    ),
                                  )
                                : null,
                            onTap: () {
                              onSelected(name);
                              Navigator.pop(context);
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
