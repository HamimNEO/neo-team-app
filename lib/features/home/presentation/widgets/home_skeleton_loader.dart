import 'package:flutter/material.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/theme/app_theme.dart';

/// Role-aware shimmer placeholder for the Home tab.
/// Admin and staff users see skeletons that precisely match the content they will get.
class HomeSkeletonLoader extends StatefulWidget {
  final bool isAdmin;
  const HomeSkeletonLoader({super.key, this.isAdmin = true});

  @override
  State<HomeSkeletonLoader> createState() => _HomeSkeletonLoaderState();
}

class _HomeSkeletonLoaderState extends State<HomeSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF26262E) : const Color(0xFFE6E6EC);
    final highlight =
        isDark ? const Color(0xFF34343F) : const Color(0xFFF4F4F8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        Widget bone(
                {double? width,
                required double height,
                double radius = 8,
                bool card = false,
                BoxShape shape = BoxShape.rectangle}) =>
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                shape: shape,
                borderRadius:
                    shape == BoxShape.circle ? null : BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment(-1.6 + t * 3.2, -0.3),
                  end: Alignment(-0.6 + t * 3.2, 0.3),
                  colors: card
                      ? [nec.surface, highlight.withValues(alpha: 0.55), nec.surface]
                      : [base, highlight, base],
                  stops: const [0.15, 0.5, 0.85],
                ),
              ),
            );

        Widget attendanceSkeleton() => Container(
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: nec.separator.withValues(alpha: 0.15),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      bone(width: 38, height: 38, radius: 12),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bone(width: 120, height: 13, radius: 4),
                          const SizedBox(height: 5),
                          bone(width: 90, height: 9, radius: 4),
                        ],
                      ),
                      const Spacer(),
                      bone(width: 80, height: 26, radius: 13),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      bone(width: 110, height: 24, radius: 6),
                      const SizedBox(width: 8),
                      bone(width: 80, height: 12, radius: 4),
                      const Spacer(),
                      bone(width: 35, height: 14, radius: 4),
                    ],
                  ),
                  const SizedBox(height: 10),
                  bone(height: 6, radius: 3),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : nec.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        bone(width: 70, height: 18, radius: 4),
                        bone(width: 70, height: 18, radius: 4),
                        bone(width: 70, height: 18, radius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            );

        Widget listCard(int rows) => Container(
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                children: [
                  for (var i = 0; i < rows; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                      child: Row(children: [
                        bone(width: 36, height: 36, radius: 10),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bone(height: 12, width: 150),
                              const SizedBox(height: 7),
                              bone(height: 9, width: 100),
                            ],
                          ),
                        ),
                      ]),
                    ),
                ],
              ),
            );

        Widget header(double width) => Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: bone(width: width, height: 11, radius: 5),
            );

        Widget tiles(int count) {
          final rows = <Widget>[];
          for (var i = 0; i < count; i += 2) {
            final two = i + 1 < count;
            rows.add(Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: Row(children: [
                Expanded(child: bone(height: 88, radius: 16, card: true)),
                if (two) ...[
                  const SizedBox(width: 8),
                  Expanded(child: bone(height: 88, radius: 16, card: true)),
                ],
              ]),
            ));
          }
          return Column(children: rows);
        }

        final access = StaffAccessStore.instance;
        bool can(StaffPermission p) => access.allows(p);

        final children = <Widget>[
          // Greeting bar (shared)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bone(width: 90, height: 11, radius: 5),
                    const SizedBox(height: 8),
                    bone(width: 150, height: 24, radius: 8),
                    const SizedBox(height: 8),
                    bone(width: 110, height: 10, radius: 5),
                  ],
                ),
                Row(children: [
                  bone(width: 38, height: 38, shape: BoxShape.circle),
                  const SizedBox(width: 8),
                  bone(width: 38, height: 38, shape: BoxShape.circle),
                  const SizedBox(width: 8),
                  bone(width: 38, height: 38, shape: BoxShape.circle),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (widget.isAdmin) ...[
            attendanceSkeleton(),
            header(60),
            tiles(4),
            header(110),
            listCard(3),
            header(70),
            listCard(4),
          ] else ...[
            if (can(StaffPermission.attendance)) ...[
              attendanceSkeleton(),
              const SizedBox(height: 6),
            ],
            if (StaffAccessStore.instance.allows(StaffPermission.leads) ||
                can(StaffPermission.followUps) ||
                can(StaffPermission.visits) ||
                can(StaffPermission.tasks)) ...[
              header(90),
              tiles([
                StaffPermission.leads,
                StaffPermission.followUps,
                StaffPermission.visits,
                StaffPermission.tasks
              ].where(can).length),
            ],
            if (can(StaffPermission.followUps)) ...[
              header(110),
              listCard(2),
            ],
            if (can(StaffPermission.followUps) || can(StaffPermission.visits)) ...[
              header(60),
              listCard(3),
            ],
            if (can(StaffPermission.tasks) || can(StaffPermission.issues)) ...[
              header(70),
              listCard(
                  can(StaffPermission.tasks) && can(StaffPermission.issues)
                      ? 2
                      : 1),
            ],
          ],
          const SizedBox(height: 24),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      },
    );
  }
}
