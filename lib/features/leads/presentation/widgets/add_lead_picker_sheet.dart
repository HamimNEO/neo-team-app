import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AddLeadPickerSheet extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String? selectedValue;
  final Set<String>? selectedMultiValues;
  final bool isMultiSelect;
  final ValueChanged<dynamic> onSelected;

  const AddLeadPickerSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
    this.selectedMultiValues,
    this.isMultiSelect = false,
    required this.onSelected,
  });

  @override
  State<AddLeadPickerSheet> createState() => _AddLeadPickerSheetState();
}

class _AddLeadPickerSheetState extends State<AddLeadPickerSheet> {
  late Set<String> _multiSet;

  @override
  void initState() {
    super.initState();
    _multiSet = Set.from(widget.selectedMultiValues ?? {});
  }

  Widget _buildCheckbox(bool isChecked) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isChecked ? nec.brand : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color:
              isChecked ? nec.brand : nec.textTertiary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: isChecked
          ? const Icon(
              CupertinoIcons.checkmark_alt,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final sheetHeight = MediaQuery.of(context).size.height * 0.65;

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                      ),
                    ),
                    if (widget.isMultiSelect)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          widget.onSelected(_multiSet);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: nec.brand,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (widget.title == 'Current HMS' ||
                        widget.title == 'Interested Plan' ||
                        widget.title == 'Contact Role')
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: nec.brand,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(widget.options.length, (index) {
                      final item = widget.options[index];
                      final label = item['label'] as String;
                      final subtitle = item['subtitle'] as String?;
                      final icon = item['icon'] as IconData?;
                      final iconColor = item['color'] as Color?;
                      final emoji = item['emoji'] as String?;
                      final isSelected = widget.isMultiSelect
                          ? _multiSet.contains(label)
                          : widget.selectedValue == label;
                      final isLast = index == widget.options.length - 1;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              if (widget.isMultiSelect) {
                                setState(() {
                                  if (_multiSet.contains(label)) {
                                    _multiSet.remove(label);
                                  } else {
                                    _multiSet.add(label);
                                  }
                                });
                              } else {
                                widget.onSelected(label);
                                Navigator.pop(context);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 14),
                              child: Row(
                                children: [
                                  if (icon != null) ...[
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: (iconColor ?? nec.brand)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 18,
                                        color: iconColor ?? nec.brand,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ] else if (emoji != null) ...[
                                    Text(emoji,
                                        style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? nec.brand
                                                : nec.textPrimary,
                                          ),
                                        ),
                                        if (subtitle != null &&
                                            subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: nec.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (widget.isMultiSelect)
                                    _buildCheckbox(isSelected)
                                  else if (isSelected)
                                    Icon(
                                      CupertinoIcons.checkmark_alt,
                                      size: 18,
                                      color: nec.brand,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: nec.separator.withValues(alpha: 0.2),
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
