import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import 'add_lead_picker_sheet.dart';
import 'lead_location_map_picker.dart';

class AddLeadStep1 extends StatelessWidget {
  final TextEditingController companyController;
  final TextEditingController locationController;
  final String? selectedBusinessType;
  final ValueChanged<String> onBusinessTypeChanged;
  final VoidCallback onNext;
  final double? latitude;
  final double? longitude;
  final ValueChanged<LocationPickResult>? onLocationPicked;
  final VoidCallback? onClearCoordinates;

  const AddLeadStep1({
    super.key,
    required this.companyController,
    required this.locationController,
    required this.selectedBusinessType,
    required this.onBusinessTypeChanged,
    required this.onNext,
    this.latitude,
    this.longitude,
    this.onLocationPicked,
    this.onClearCoordinates,
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

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await LeadLocationMapPicker.show(
      context,
      initialLocation: locationController.text.trim().isNotEmpty
          ? locationController.text.trim()
          : null,
      initialLatitude: latitude,
      initialLongitude: longitude,
    );
    if (result != null) {
      locationController.text = result.locationName;
      onLocationPicked?.call(result);
    }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(fontSize: 13, color: nec.textTertiary),
                    ),
                    InkWell(
                      onTap: () => _openMapPicker(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.map_pin_ellipse,
                              size: 14,
                              color: nec.brand,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pick on Map',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: nec.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                if (latitude != null && longitude != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: nec.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: nec.brand.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.location_fill,
                            size: 13, color: nec.brand),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Coordinates: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: nec.brand,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _openMapPicker(context),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: nec.brand,
                            ),
                          ),
                        ),
                        if (onClearCoordinates != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onClearCoordinates,
                            child: Icon(CupertinoIcons.clear_circled,
                                size: 14, color: nec.textTertiary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _openMapPicker(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: nec.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: nec.separator.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.map,
                              size: 14, color: nec.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap to select & pin on interactive map',
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textSecondary,
                              ),
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_right,
                              size: 12, color: nec.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ],
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
