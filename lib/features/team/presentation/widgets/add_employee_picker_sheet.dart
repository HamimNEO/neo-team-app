import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PickerOption {
  final String title;
  final String? subtitle;
  final String? value;

  const PickerOption({required this.title, this.subtitle, this.value});
}

class AddEmployeePickerSheet extends StatelessWidget {
  final String title;
  final List<PickerOption> options;
  final String? selectedValue;
  final ValueChanged<PickerOption> onSelected;

  const AddEmployeePickerSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(options.length, (index) {
                    final item = options[index];
                    final isSelected =
                        selectedValue == (item.value ?? item.title);
                    final isLast = index == options.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected ? nec.brand : nec.textPrimary,
                            ),
                          ),
                          subtitle: item.subtitle != null
                              ? Text(
                                  item.subtitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: nec.textTertiary,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(
                                  CupertinoIcons.checkmark,
                                  color: nec.brand,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(context);
                          },
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.2),
                            indent: 20,
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
    );
  }
}
