import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

class AppearanceThemeTile extends StatelessWidget {
  final AppThemeMode mode;
  final String title;
  final String description;
  final String iconEmoji;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  const AppearanceThemeTile({
    super.key,
    required this.mode,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: nec.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(iconEmoji, style: const TextStyle(fontSize: 22)),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: nec.textPrimary,
            ),
          ),
          subtitle: Text(
            description,
            style: TextStyle(fontSize: 12, color: nec.textTertiary),
          ),
          trailing:
              isSelected ? Icon(Icons.check, color: nec.brand, size: 20) : null,
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            indent: 70,
            endIndent: 0,
            height: 0.5,
            color: nec.separator,
          ),
      ],
    );
  }
}
