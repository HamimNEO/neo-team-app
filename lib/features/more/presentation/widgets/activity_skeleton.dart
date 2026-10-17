import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ActivitySkeleton extends StatefulWidget {
  const ActivitySkeleton({super.key});

  @override
  State<ActivitySkeleton> createState() => _ActivitySkeletonState();
}

class _ActivitySkeletonState extends State<ActivitySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          Widget bone(double width, double height, {double radius = 8}) =>
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment(-2 + _controller.value * 4, 0),
                    end: Alignment(-1 + _controller.value * 4, 0),
                    colors: [
                      nec.separator.withValues(alpha: .25),
                      nec.surface,
                      nec.separator.withValues(alpha: .25),
                    ],
                  ),
                ),
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bone(60, 12),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: List.generate(
                    4,
                    (index) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              bone(32, 32, radius: 10),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    bone(180, 14),
                                    const SizedBox(height: 6),
                                    bone(60, 11),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < 3)
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.2),
                            indent: 58,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              bone(80, 12),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              bone(32, 32, radius: 10),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    bone(160, 14),
                                    const SizedBox(height: 6),
                                    bone(50, 11),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < 2)
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.2),
                            indent: 58,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
