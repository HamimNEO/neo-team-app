import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import 'add_lead_picker_sheet.dart';

class AddLeadStep1 extends StatelessWidget {
  final TextEditingController companyController;
  final TextEditingController locationController;
  final String? selectedBusinessType;
  final ValueChanged<String> onBusinessTypeChanged;
  final VoidCallback onNext;

  const AddLeadStep1({
    super.key,
    required this.companyController,
    required this.locationController,
    required this.selectedBusinessType,
    required this.onBusinessTypeChanged,
    required this.onNext,
  });

  void _openBusinessTypePicker(BuildContext context) {
    final businessTypes = [
      {
        'label': 'Hotel',
        'icon': CupertinoIcons.house_alt_fill,
        'color': AppColors.brandLight,
      },
      {
        'label': 'Resort',
        'icon': CupertinoIcons.sun_max_fill,
        'color': AppColors.warning,
      },
      {
        'label': 'Guest House',
        'icon': CupertinoIcons.house_fill,
        'color': AppColors.success,
      },
      {
        'label': 'Restaurant',
        'icon': CupertinoIcons.circle_grid_hex_fill,
        'color': AppColors.leadVisit,
      },
      {
        'label': 'Company',
        'icon': CupertinoIcons.briefcase_fill,
        'color': AppColors.leadContacted,
      },
      {
        'label': 'Agency',
        'icon': CupertinoIcons.doc_plaintext,
        'color': AppColors.leadNegotiation,
      },
      {
        'label': 'Other',
        'icon': CupertinoIcons.ellipsis_circle_fill,
        'color': AppColors.neutral,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddLeadPickerSheet(
        title: 'Business Type',
        options: businessTypes,
        selectedValue: selectedBusinessType,
        onSelected: (val) => onBusinessTypeChanged(val as String),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isValid = companyController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'BUSINESS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: nec.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business / Client Name *',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: companyController,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Sea Pearl Resort',
                    hintStyle: TextStyle(color: nec.textTertiary, fontSize: 16),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text(
                  'Business Type',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openBusinessTypePicker(context),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.tag,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedBusinessType ?? 'Select type',
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedBusinessType != null
                                ? nec.textPrimary
                                : nec.textTertiary,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text(
                  'Location',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: locationController,
                  style: TextStyle(
                    fontSize: 15,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: "Cox's Bazar",
                    hintStyle: TextStyle(color: nec.textTertiary, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          NecButton(
            label: 'Next: Contact Person',
            onPressed: isValid ? onNext : () {},
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
