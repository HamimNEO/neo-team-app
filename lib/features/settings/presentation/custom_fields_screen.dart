import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';

class CustomFieldItem {
  final String name;
  final String type;
  bool isEnabled;

  CustomFieldItem({
    required this.name,
    required this.type,
    this.isEnabled = true,
  });
}

class CustomFieldsScreen extends StatefulWidget {
  const CustomFieldsScreen({super.key});

  @override
  State<CustomFieldsScreen> createState() => _CustomFieldsScreenState();
}

class _CustomFieldsScreenState extends State<CustomFieldsScreen> {
  late List<CustomFieldItem> _fields;

  @override
  void initState() {
    super.initState();
    _fields = [
      CustomFieldItem(name: 'Budget Range', type: 'Single Select'),
      CustomFieldItem(name: 'Number of Rooms', type: 'Number'),
      CustomFieldItem(
          name: 'Expected Check-in', type: 'Date', isEnabled: false),
    ];
  }

  void _openAddFieldSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddCustomFieldSheet(
        onAdded: (name, type) {
          setState(() {
            _fields.add(CustomFieldItem(name: name, type: type));
          });
          NecToast.show(
            context,
            message: 'Custom field "$name" added',
            type: NecToastType.success,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.pop();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: nec.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: nec.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  'Custom Fields',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(CupertinoIcons.add, color: nec.brand, size: 22),
                onPressed: _openAddFieldSheet,
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: nec.separator.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom fields extend lead records with data specific to your operations.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: nec.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(_fields.length, (index) {
                    final item = _fields[index];
                    final isLast = index == _fields.length - 1;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.type,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: nec.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Switch.adaptive(
                                value: item.isEnabled,
                                activeTrackColor: AppColors.success,
                                onChanged: (val) {
                                  setState(() {
                                    item.isEnabled = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.2),
                            indent: 16,
                          ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCustomFieldSheet extends StatefulWidget {
  final Function(String name, String type) onAdded;

  const _AddCustomFieldSheet({required this.onAdded});

  @override
  State<_AddCustomFieldSheet> createState() => _AddCustomFieldSheetState();
}

class _AddCustomFieldSheetState extends State<_AddCustomFieldSheet> {
  final _nameController = TextEditingController();
  final List<String> _types = [
    'Text',
    'Number',
    'Date',
    'Single Select',
    'Multi Select',
    'Yes / No',
  ];
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = _types.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      NecToast.show(
        context,
        message: 'Please enter a field name',
        type: NecToastType.error,
      );
      return;
    }
    widget.onAdded(name, _selectedType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Add Custom Field',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'FIELD NAME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Budget Range',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: nec.textTertiary,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FIELD TYPE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: _types.map((type) {
                  final isSel = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.brandLight
                            : (isDark
                                ? nec.bg
                                : nec.separator.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel
                              ? AppColors.brandLight
                              : nec.separator.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? Colors.white : nec.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              NecButton(
                label: 'Add Field',
                onPressed: _submit,
                fullWidth: true,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
