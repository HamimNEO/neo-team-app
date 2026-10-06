import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class SelectLeadSheet extends StatefulWidget {
  final String? currentLeadName;

  const SelectLeadSheet({
    super.key,
    this.currentLeadName,
  });

  @override
  State<SelectLeadSheet> createState() => _SelectLeadSheetState();
}

class _SelectLeadSheetState extends State<SelectLeadSheet> {
  final _searchController = TextEditingController();

  final List<String> _allLeads = [
    'Blue Wave Resort',
    'Sea Pearl Resort',
    'Green Palm Hotel',
    'Ocean Nest Hotel',
    'Sunrise Guest House',
    'Coral Bay Resort',
    'Bay Garden Hotel',
    'Seagull Hotel',
    'Hilltop Inn',
    'Palm View Resort',
    'Marine Drive Hotel',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final query = _searchController.text.trim().toLowerCase();
    final filteredLeads = query.isEmpty
        ? _allLeads
        : _allLeads.where((l) => l.toLowerCase().contains(query)).toList();

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
            Text(
              'Select Lead',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 16,
                      color: nec.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 14,
                          color: nec.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search lead...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: nec.textTertiary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredLeads.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.2),
                ),
                itemBuilder: (context, index) {
                  final lead = filteredLeads[index];
                  final isSelected = lead == widget.currentLeadName;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brandLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.building_2_fill,
                        color: AppColors.brandLight,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      lead,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: nec.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: AppColors.brandLight,
                            size: 18,
                          )
                        : Icon(
                            CupertinoIcons.add,
                            color: nec.textTertiary,
                            size: 18,
                          ),
                    onTap: () {
                      Navigator.pop(context, lead);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
