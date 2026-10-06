import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class IssueFilterSheet extends StatefulWidget {
  final String? selectedPriority;
  final ValueChanged<String?> onApply;

  const IssueFilterSheet({
    super.key,
    this.selectedPriority,
    required this.onApply,
  });

  @override
  State<IssueFilterSheet> createState() => _IssueFilterSheetState();
}

class _IssueFilterSheetState extends State<IssueFilterSheet> {
  String? _priority;

  final priorities = ['Urgent', 'High', 'Normal', 'Low'];

  @override
  void initState() {
    super.initState();
    _priority = widget.selectedPriority;
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  'Filter Issues',
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
                'PRIORITY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: priorities.map((opt) {
                  final isSelected = _priority == opt;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _priority = isSelected ? null : opt;
                      });
                      widget.onApply(_priority);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? nec.brand.withValues(alpha: 0.15)
                            : nec.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? nec.brand
                              : nec.separator.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? nec.brand : nec.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _priority = null;
                    });
                    widget.onApply(null);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nec.bg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Clear Filters',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
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
