import 'dart:math' as math;
import 'package:flutter/material.dart';

enum TimeOfDayPeriod {
  morning,
  afternoon,
  evening,
  night,
}

TimeOfDayPeriod getTimeOfDayPeriod([DateTime? now]) {
  final dt = now ?? DateTime.now();
  final hour = dt.hour;
  if (hour >= 5 && hour < 12) {
    return TimeOfDayPeriod.morning;
  } else if (hour >= 12 && hour < 17) {
    return TimeOfDayPeriod.afternoon;
  } else if (hour >= 17 && hour < 21) {
    return TimeOfDayPeriod.evening;
  } else {
    return TimeOfDayPeriod.night;
  }
}

class HomeHeaderPainter extends CustomPainter {
  final TimeOfDayPeriod period;
  final bool isDark;
  final Color bgColor;

  HomeHeaderPainter({
    required this.period,
    required this.isDark,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final skyColors = _getSkyColors(period, isDark);
    final skyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: skyColors,
    );
    final skyPaint = Paint()..shader = skyGradient.createShader(rect);
    canvas.drawRect(rect, skyPaint);

    _paintCelestialObject(canvas, size);

    _paintWaveCurves(canvas, size);

    if (period == TimeOfDayPeriod.night) {
      _paintStarParticles(canvas, size);
    } else {
      _paintSoftClouds(canvas, size);
    }

    final fadeRect =
        Rect.fromLTRB(0, size.height * 0.50, size.width, size.height);
    final fadeGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        bgColor.withValues(alpha: 0.0),
        bgColor.withValues(alpha: 0.45),
        bgColor,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final fadePaint = Paint()..shader = fadeGradient.createShader(fadeRect);
    canvas.drawRect(fadeRect, fadePaint);
  }

  List<Color> _getSkyColors(TimeOfDayPeriod period, bool isDark) {
    if (isDark) {
      switch (period) {
        case TimeOfDayPeriod.morning:
          return const [
            Color(0xFF13182A),
            Color(0xFF1E1E3B),
            Color(0xFF281D35)
          ];
        case TimeOfDayPeriod.afternoon:
          return const [
            Color(0xFF12182B),
            Color(0xFF1C223C),
            Color(0xFF26223C)
          ];
        case TimeOfDayPeriod.evening:
          return const [
            Color(0xFF1B142A),
            Color(0xFF2C1B33),
            Color(0xFF351E30)
          ];
        case TimeOfDayPeriod.night:
          return const [
            Color(0xFF0B0E1B),
            Color(0xFF11162C),
            Color(0xFF1A152E)
          ];
      }
    } else {
      switch (period) {
        case TimeOfDayPeriod.morning:
          return const [
            Color(0xFFFFF7EC),
            Color(0xFFFFF0FA),
            Color(0xFFEFF4FF)
          ];
        case TimeOfDayPeriod.afternoon:
          return const [
            Color(0xFFF7F3FF),
            Color(0xFFEDF2FF),
            Color(0xFFF4EFFF)
          ];
        case TimeOfDayPeriod.evening:
          return const [
            Color(0xFFFFF1EE),
            Color(0xFFFCF0FF),
            Color(0xFFEFF2FF)
          ];
        case TimeOfDayPeriod.night:
          return const [
            Color(0xFFEEEBF8),
            Color(0xFFE3E6FC),
            Color(0xFFE9E5F8)
          ];
      }
    }
  }

  void _paintCelestialObject(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.58, size.height * 0.32);
    final radius = math.max(28.0, size.height * 0.28);

    if (period == TimeOfDayPeriod.night) {
      final auraPaint = Paint()
        ..color = (isDark ? const Color(0xFF9E86FF) : const Color(0xFF7A6CF0))
            .withValues(alpha: isDark ? 0.25 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawCircle(center, radius * 1.5, auraPaint);

      final moonPaint = Paint()
        ..color = isDark ? const Color(0xFFE2E8FF) : const Color(0xFF8B82FE);
      canvas.drawCircle(center, radius, moonPaint);

      final shadowPaint = Paint()..color = _getSkyColors(period, isDark)[1];
      canvas.drawCircle(
          Offset(center.dx - radius * 0.45, center.dy - radius * 0.2),
          radius * 0.9,
          shadowPaint);
    } else {
      final auraColor = switch (period) {
        TimeOfDayPeriod.morning => const Color(0xFFFFB84D),
        TimeOfDayPeriod.afternoon => const Color(0xFFFFC043),
        TimeOfDayPeriod.evening => const Color(0xFFFF7B43),
        _ => const Color(0xFFFFC043),
      };

      final auraPaint = Paint()
        ..color = auraColor.withValues(alpha: isDark ? 0.22 : 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
      canvas.drawCircle(center, radius * 1.8, auraPaint);

      final sunPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            auraColor,
            auraColor.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, sunPaint);
    }
  }

  void _paintWaveCurves(Canvas canvas, Size size) {
    final waveColor1 = isDark
        ? const Color(0xFF8A52F3).withValues(alpha: 0.14)
        : const Color(0xFFDCD2FE).withValues(alpha: 0.55);

    final waveColor2 = isDark
        ? const Color(0xFF5B6BFF).withValues(alpha: 0.12)
        : const Color(0xFFE8EBFF).withValues(alpha: 0.65);

    final p1 = Path();
    p1.moveTo(0, size.height * 0.72);
    p1.cubicTo(
      size.width * 0.25,
      size.height * 0.85,
      size.width * 0.65,
      size.height * 0.35,
      size.width,
      size.height * 0.45,
    );
    p1.lineTo(size.width, size.height);
    p1.lineTo(0, size.height);
    p1.close();

    canvas.drawPath(p1, Paint()..color = waveColor1);

    final p2 = Path();
    p2.moveTo(0, size.height * 0.85);
    p2.cubicTo(
      size.width * 0.35,
      size.height * 0.60,
      size.width * 0.75,
      size.height * 0.90,
      size.width,
      size.height * 0.70,
    );
    p2.lineTo(size.width, size.height);
    p2.lineTo(0, size.height);
    p2.close();

    canvas.drawPath(p2, Paint()..color = waveColor2);
  }

  void _paintStarParticles(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 22; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.65;
      final radius = 0.8 + rnd.nextDouble() * 1.4;
      final opacity = 0.3 + rnd.nextDouble() * 0.6;
      starPaint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _paintSoftClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.white)
          .withValues(alpha: isDark ? 0.08 : 0.45);

    final path = Path();
    final cx = size.width * 0.52;
    final cy = size.height * 0.42;

    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: 26));
    path.addOval(Rect.fromCircle(center: Offset(cx - 20, cy + 6), radius: 20));
    path.addOval(Rect.fromCircle(center: Offset(cx + 22, cy + 8), radius: 18));
    path.addOval(Rect.fromCircle(center: Offset(cx + 42, cy + 12), radius: 14));

    canvas.drawPath(path, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! HomeHeaderPainter) return true;
    return oldDelegate.period != period ||
        oldDelegate.isDark != isDark ||
        oldDelegate.bgColor != bgColor;
  }
}
