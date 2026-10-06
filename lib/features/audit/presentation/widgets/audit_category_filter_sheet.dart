import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/audit_entry.dart';
import 'audit_style.dart';

class AuditCategoryFilterSheet extends StatelessWidget {
  final AuditCategory? selectedCategory;
  final ValueChanged<AuditCategory?> onSelected;

  const AuditCategoryFilterSheet({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final categories = <AuditCategory?>[null, ...AuditCategory.values];

    return FractionallySizedBox(
      heightFactor: 0.62,
      child: Material(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: nec.textTertiary.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Filter by Category',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                ),
              ),
              Divider(height: 1, thickness: 0.5, color: nec.separator),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: nec.separator,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final selected = category == selectedCategory;
                    return Semantics(
                      selected: selected,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        onPressed: () {
                          onSelected(category);
                          Navigator.of(context).pop();
                        },
                        child: Row(
                          children: [
                            if (category != null) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: auditCategoryColor(category),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                category?.label ?? 'All Categories',
                                style: TextStyle(
                                    fontSize: 16, color: nec.textPrimary),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: selected
                                  ? DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: nec.brand,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
