import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class AuditAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String fallbackPath;
  final VoidCallback? onFilter;
  final bool filtered;

  const AuditAppBar({
    super.key,
    required this.title,
    required this.fallbackPath,
    this.onFilter,
    this.filtered = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return AppBar(
      backgroundColor: nec.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          SizedBox(
            width: 68,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(fallbackPath),
              child: Row(
                children: [
                  Icon(CupertinoIcons.chevron_left, size: 17, color: nec.brand),
                  const SizedBox(width: 5),
                  Text('Back',
                      style: TextStyle(fontSize: 17, color: nec.brand)),
                ],
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: nec.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: onFilter == null
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: Tooltip(
                      message: 'Filter by category',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: onFilter,
                        child: Icon(
                          CupertinoIcons.line_horizontal_3_decrease,
                          size: 21,
                          color: filtered ? nec.brand : nec.textSecondary,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 0.5, color: nec.separator),
      ),
    );
  }
}
