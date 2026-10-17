import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationSkeleton extends StatefulWidget {
  const NotificationSkeleton({super.key});

  @override
  State<NotificationSkeleton> createState() => _NotificationSkeletonState();
}

class _NotificationSkeletonState extends State<NotificationSkeleton>
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            Widget bone(double width, double height) => Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment(-2 + _controller.value * 4, 0),
                        end: Alignment(-1 + _controller.value * 4, 0),
                        colors: [
                          nec.separator.withValues(alpha: .25),
                          nec.surface,
                          nec.separator.withValues(alpha: .25)
                        ],
                      )),
                );
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bone(80, 14),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                        children: List.generate(
                            7,
                            (_) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(children: [
                                    bone(36, 36),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          bone(170, 14),
                                          const SizedBox(height: 8),
                                          bone(double.infinity, 12),
                                          const SizedBox(height: 8),
                                          bone(55, 10),
                                        ])),
                                  ]),
                                ))),
                  ),
                ]);
          }),
    );
  }
}
