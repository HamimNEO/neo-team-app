import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import 'add_lead_picker_sheet.dart';

class AddLeadStep4 extends StatelessWidget {
  final String? selectedPlan;
  final Set<String> selectedServices;
  final ValueChanged<String> onPlanChanged;
  final ValueChanged<Set<String>> onServicesChanged;
  final VoidCallback onNext;

  const AddLeadStep4({
    super.key,
    required this.selectedPlan,
    required this.selectedServices,
    required this.onPlanChanged,
    required this.onServicesChanged,
    required this.onNext,
  });

  void _openPlanPicker(BuildContext context) {
    final plans = [
      {'label': 'Online Only'},
      {'label': 'Online + Offline'},
      {'label': 'Complete'},
      {'label': 'Enterprise'},
      {'label': 'Custom'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddLeadPickerSheet(
        title: 'Interested Plan',
        options: plans,
        selectedValue: selectedPlan,
        onSelected: (val) => onPlanChanged(val as String),
      ),
    );
  }

  void _openServicesPicker(BuildContext context) {
    final services = [
      {'label': 'Hotel Management'},
      {'label': 'Hotel Website'},
      {'label': 'Marketplace'},
      {'label': 'Guest App'},
      {'label': 'Restaurant'},
      {'label': 'Payment'},
      {'label': 'Communication'},
      {'label': 'Custom Solution'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddLeadPickerSheet(
        title: 'Interested Services',
        options: services,
        selectedMultiValues: selectedServices,
        isMultiSelect: true,
        onSelected: (val) => onServicesChanged(val as Set<String>),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'INTEREST',
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
                  'Interested Plan',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openPlanPicker(context),
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
                          selectedPlan ?? 'Select plan',
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedPlan != null
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
                  'Interested Services',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openServicesPicker(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedServices.isNotEmpty
                              ? selectedServices.join(', ')
                              : 'Select services',
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedServices.isNotEmpty
                                ? nec.textPrimary
                                : nec.textTertiary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
          const SizedBox(height: 32),
          NecButton(
            label: 'Next: Assignment & Final',
            onPressed: onNext,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
