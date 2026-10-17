import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TasksSkeletonLoader extends StatefulWidget {
  final int itemCount;

  const TasksSkeletonLoader({super.key, this.itemCount = 5});

  @override
  State<TasksSkeletonLoader> createState() => _TasksSkeletonLoaderState();
}

class _TasksSkeletonLoaderState extends State<TasksSkeletonLoader>
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
    final base = isDark ? const Color(0xFF26262E) : const Color(0xFFE8E8EE);
    final highlight =
        isDark ? const Color(0xFF383844) : const Color(0xFFF6F6FA);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        Widget bone({
          double? width,
          required double height,
          double radius = 8,
          BoxShape shape = BoxShape.rectangle,
        }) =>
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: shape == BoxShape.circle
                    ? null
                    : BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment(-1.6 + t * 3.2, -0.3),
                  end: Alignment(-0.6 + t * 3.2, 0.3),
                  colors: [base, highlight, base],
                  stops: const [0.15, 0.5, 0.85],
                ),
              ),
            );

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: nec.separator.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bone(width: 22, height: 22, radius: 6),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bone(
                            width: 130 + (index % 3) * 35.0,
                            height: 16,
                            radius: 4),
                        const SizedBox(height: 8),
                        bone(width: 90, height: 12, radius: 4),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            bone(width: 55, height: 20, radius: 10),
                            const SizedBox(width: 8),
                            bone(
                                width: 20,
                                height: 20,
                                radius: 10,
                                shape: BoxShape.circle),
                            const SizedBox(width: 6),
                            bone(width: 80, height: 12, radius: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
