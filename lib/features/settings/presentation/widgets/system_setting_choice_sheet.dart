import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SystemSettingChoice {
  final String value;
  final String label;
  final String? subtitle;
  final Color? color;

  const SystemSettingChoice({
    required this.value,
    required this.label,
    this.subtitle,
    this.color,
  });
}

class SystemSettingChoiceSheet extends StatelessWidget {
  final String title;
  final String selectedValue;
  final List<SystemSettingChoice> choices;
  final ValueChanged<String> onSelected;

  const SystemSettingChoiceSheet({
    super.key,
    required this.title,
    required this.selectedValue,
    required this.choices,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return FractionallySizedBox(
      heightFactor: 0.58,
      child: Material(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: nec.textTertiary.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                ),
              ),
              Divider(height: 1, color: nec.separator),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: choices.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: nec.separator),
                  itemBuilder: (context, index) {
                    final choice = choices[index];
                    return Semantics(
                      selected: choice.value == selectedValue,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSelected(choice.value);
                        },
                        child: Row(
                          children: [
                            if (choice.color != null) ...[
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: choice.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    choice.label,
                                    style: TextStyle(
                                        fontSize: 16, color: nec.textPrimary),
                                  ),
                                  if (choice.subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      choice.subtitle!,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: nec.textTertiary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (choice.value == selectedValue)
                              Icon(CupertinoIcons.check_mark,
                                  size: 20, color: nec.brand)
                            else
                              const SizedBox(width: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
