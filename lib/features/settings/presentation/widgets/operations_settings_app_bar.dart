import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class OperationsSettingsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String fallbackPath;
  final bool centerTitle;

  const OperationsSettingsAppBar({
    super.key,
    required this.title,
    this.fallbackPath = '/administration',
    this.centerTitle = true,
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
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(fallbackPath),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.chevron_left, color: nec.brand, size: 17),
                const SizedBox(width: 5),
                Text('Back', style: TextStyle(color: nec.brand, fontSize: 17)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
              child: Text(
                title,
                textAlign: centerTitle ? TextAlign.center : TextAlign.left,
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
          if (centerTitle) const SizedBox(width: 68),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 0.5, color: nec.separator),
      ),
    );
  }
}
