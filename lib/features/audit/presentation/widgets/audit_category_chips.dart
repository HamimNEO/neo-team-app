import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/audit_entry.dart';

class AuditCategoryChips extends StatefulWidget {
  final AuditCategory? selectedCategory;
  final ValueChanged<AuditCategory?> onSelected;

  const AuditCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  State<AuditCategoryChips> createState() => _AuditCategoryChipsState();
}

class _AuditCategoryChipsState extends State<AuditCategoryChips> {
  final _chipKeys =
      List.generate(AuditCategory.values.length + 1, (_) => GlobalKey());

  @override
  void didUpdateWidget(covariant AuditCategoryChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory == widget.selectedCategory) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = widget.selectedCategory == null
          ? 0
          : widget.selectedCategory!.index + 1;
      final chipContext = _chipKeys[index].currentContext;
      if (chipContext == null) return;
      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final categories = <AuditCategory?>[null, ...AuditCategory.values];

    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var index = 0; index < categories.length; index++) ...[
              Semantics(
                selected: categories[index] == widget.selectedCategory,
                child: CupertinoButton(
                  key: _chipKeys[index],
                  padding: EdgeInsets.zero,
                  onPressed: () => widget.onSelected(categories[index]),
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: categories[index] == widget.selectedCategory
                          ? nec.brand
                          : nec.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: categories[index] == widget.selectedCategory
                            ? nec.brand
                            : nec.separator.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      categories[index]?.label ?? 'All',
                      style: TextStyle(
                        fontSize: 13,
                        color: categories[index] == widget.selectedCategory
                            ? Colors.white
                            : nec.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              if (index < categories.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}
