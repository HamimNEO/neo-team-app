import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LeadsSkeletonLoader extends StatefulWidget {
  final int itemCount;

  const LeadsSkeletonLoader({super.key, this.itemCount = 5});

  @override
  State<LeadsSkeletonLoader> createState() => _LeadsSkeletonLoaderState();
}

class _LeadsSkeletonLoaderState extends State<LeadsSkeletonLoader>
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      bone(
                          width: 140 + (index % 3) * 30.0,
                          height: 16,
                          radius: 4),
                      bone(width: 65, height: 22, radius: 11),
                    ],
                  ),
                  const SizedBox(height: 8),
                  bone(width: 180, height: 12, radius: 4),
                  const SizedBox(height: 14),
                  Container(
                    height: 0.5,
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      bone(
                          width: 26,
                          height: 26,
                          radius: 13,
                          shape: BoxShape.circle),
                      const SizedBox(width: 8),
                      bone(width: 100, height: 12, radius: 4),
                      const Spacer(),
                      bone(width: 50, height: 11, radius: 4),
                    ],
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
