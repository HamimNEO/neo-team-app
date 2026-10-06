import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import 'add_lead_picker_sheet.dart';

class AddLeadStep2 extends StatelessWidget {
  final TextEditingController contactNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final String? selectedRole;
  final bool isWhatsAppSame;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<bool> onWhatsAppSameChanged;
  final VoidCallback onNext;

  const AddLeadStep2({
    super.key,
    required this.contactNameController,
    required this.phoneController,
    required this.emailController,
    required this.selectedRole,
    required this.isWhatsAppSame,
    required this.onRoleChanged,
    required this.onWhatsAppSameChanged,
    required this.onNext,
  });

  void _openRolePicker(BuildContext context) {
    final roles = [
      {'label': 'Owner'},
      {'label': 'Managing Director'},
      {'label': 'General Manager'},
      {'label': 'Manager'},
      {'label': 'Front Office Manager'},
      {'label': 'IT / Technology'},
      {'label': 'Other'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddLeadPickerSheet(
        title: 'Contact Role',
        options: roles,
        selectedValue: selectedRole,
        onSelected: (val) => onRoleChanged(val as String),
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
              'CONTACT',
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
                  'Contact Person',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: contactNameController,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Abdul Karim',
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
                  'Role / Designation',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openRolePicker(context),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.person_badge_plus,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedRole ?? 'Select role',
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedRole != null
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
                  'Phone',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.phone,
                      size: 16,
                      color: nec.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontSize: 15,
                          color: nec.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '+880 1711 234567',
                          hintStyle:
                              TextStyle(color: nec.textTertiary, fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.2)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WhatsApp same as phone',
                      style: TextStyle(
                        fontSize: 14,
                        color: nec.textPrimary,
                      ),
                    ),
                    CupertinoSwitch(
                      value: isWhatsAppSame,
                      onChanged: onWhatsAppSameChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text(
                  'Email',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontSize: 15,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'contact@business.com',
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
            label: 'Next: Property Details',
            onPressed: onNext,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
