import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AppearanceThemeTile extends StatelessWidget {
  final String title;
  final String description;
  final String iconEmoji;
  final Color primaryColor;
  final Color bgColor;
  final String tagText;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  const AppearanceThemeTile({
    super.key,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.primaryColor,
    required this.bgColor,
    required this.tagText,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : nec.separator.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(iconEmoji, style: const TextStyle(fontSize: 22)),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tagText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              description,
              style: TextStyle(
                  fontSize: 12, color: nec.textTertiary, height: 1.3),
            ),
          ),
          trailing: isSelected
              ? Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                )
              : Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: nec.separator.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            indent: 72,
            endIndent: 0,
            height: 0.5,
            color: nec.separator.withValues(alpha: 0.25),
          ),
      ],
    );
  }
}
