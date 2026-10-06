import 'package:flutter/material.dart';

class LeadTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  final Color separatorColor;

  const LeadTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
    required this.separatorColor,
  });

  @override
  double get minExtent => tabBar.preferredSize.height + 0.5;

  @override
  double get maxExtent => tabBar.preferredSize.height + 0.5;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          tabBar,
          Divider(height: 0.5, color: separatorColor),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(LeadTabBarDelegate oldDelegate) => false;
}
