import 'package:flutter/material.dart';
import 'nav_tab_item.dart';

class CurvedBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final List<NavTabItem> items;

  const CurvedBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.items,
  })  : assert(items.length > 0),
        assert(selectedIndex >= 0 && selectedIndex < items.length);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final bottomPadding = media.padding.bottom;

    final containerColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final archStrokeColor = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.08);

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final bottomMargin = isIOS
        ? (bottomPadding > 0 ? 16.0 : 12.0)
        : (bottomPadding > 0 ? bottomPadding + 8 : 22.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomMargin,
      ),
      child: SizedBox(
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.50)
                          : Colors.black.withValues(alpha: 0.10),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 5),
                    ),
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -12,
              child: CustomPaint(
                size: const Size(58, 28),
                painter: _CenterArchPainter(
                  fillColor: containerColor,
                  strokeColor: archStrokeColor,
                  isDark: isDark,
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterArchPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final bool isDark;

  _CenterArchPainter({
    required this.fillColor,
    required this.strokeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(size.width / 2),
      clockwise: true,
    );
    path.close();

    final shadowPaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path.shift(const Offset(0, 1.5)), shadowPaint);

    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(path, fillPaint);

    final strokePath = Path();
    strokePath.moveTo(2, size.height);
    strokePath.arcToPoint(
      Offset(size.width - 2, size.height),
      radius: Radius.circular((size.width - 4) / 2),
      clockwise: true,
    );

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(_CenterArchPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.isDark != isDark;
}
