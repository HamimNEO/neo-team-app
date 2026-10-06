import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import 'add_lead_picker_sheet.dart';

class AddLeadStep3 extends StatelessWidget {
  final TextEditingController propertiesController;
  final TextEditingController roomsController;
  final String? selectedHms;
  final ValueChanged<String> onHmsChanged;
  final VoidCallback onNext;

  const AddLeadStep3({
    super.key,
    required this.propertiesController,
    required this.roomsController,
    required this.selectedHms,
    required this.onHmsChanged,
    required this.onNext,
  });

  void _openHmsPicker(BuildContext context) {
    final options = [
      {'label': 'None'},
      {'label': 'Existing System'},
      {'label': 'Unknown'},
      {'label': 'IDS Next'},
      {'label': 'Opera'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddLeadPickerSheet(
        title: 'Current HMS',
        options: options,
        selectedValue: selectedHms,
        onSelected: (val) => onHmsChanged(val as String),
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
              'PROPERTY',
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
                  'Total Properties',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: propertiesController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '1',
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
                  'Total Rooms',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: roomsController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '120',
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
                  'Current HMS',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openHmsPicker(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedHms ?? 'Select software',
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedHms != null
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
              ],
            ),
          ),
          const SizedBox(height: 32),
          NecButton(
            label: 'Next: Interest & Services',
            onPressed: onNext,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
