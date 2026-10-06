import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';

class BusinessTypeItem {
  final String name;
  bool isEnabled;

  BusinessTypeItem({
    required this.name,
    this.isEnabled = true,
  });
}

class BusinessTypesScreen extends StatefulWidget {
  const BusinessTypesScreen({super.key});

  @override
  State<BusinessTypesScreen> createState() => _BusinessTypesScreenState();
}

class _BusinessTypesScreenState extends State<BusinessTypesScreen> {
  late List<BusinessTypeItem> _types;

  @override
  void initState() {
    super.initState();
    _types = [
      BusinessTypeItem(name: 'Hotel'),
      BusinessTypeItem(name: 'Resort'),
      BusinessTypeItem(name: 'Guest House'),
      BusinessTypeItem(name: 'Restaurant'),
      BusinessTypeItem(name: 'Travel Business'),
      BusinessTypeItem(name: 'Corporate'),
      BusinessTypeItem(name: 'Other'),
    ];
  }

  void _openAddTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddTypeSheet(
        onAdded: (name) {
          setState(() {
            _types.add(BusinessTypeItem(name: name));
          });
          NecToast.show(
            context,
            message: 'Business type "$name" added',
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
                  'Business Types',
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
                onPressed: _openAddTypeSheet,
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
                'Business types classify the kind of business each lead represents.',
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
                  children: List.generate(_types.length, (index) {
                    final item = _types[index];
                    final isLast = index == _types.length - 1;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
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

class _AddTypeSheet extends StatefulWidget {
  final Function(String name) onAdded;

  const _AddTypeSheet({required this.onAdded});

  @override
  State<_AddTypeSheet> createState() => _AddTypeSheetState();
}

class _AddTypeSheetState extends State<_AddTypeSheet> {
  final _nameController = TextEditingController();

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
        message: 'Please enter a business type name',
        type: NecToastType.error,
      );
      return;
    }
    widget.onAdded(name);
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
                  'Add Business Type',
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
                    hintText: 'e.g. Spa & Wellness',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: nec.textTertiary,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              NecButton(
                label: 'Add Type',
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
