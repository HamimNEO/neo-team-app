import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/sound_service.dart';

class TaskCompletionDialog extends StatefulWidget {
  final String taskTitle;
  final Future<void> Function() onConfirm;

  const TaskCompletionDialog({
    super.key,
    required this.taskTitle,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String taskTitle,
    required Future<void> Function() onConfirm,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => TaskCompletionDialog(
        taskTitle: taskTitle,
        onConfirm: onConfirm,
      ),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<TaskCompletionDialog> createState() => _TaskCompletionDialogState();
}

class _TaskCompletionDialogState extends State<TaskCompletionDialog>
    with TickerProviderStateMixin {
  bool _confirmed = false;
  bool _loading = false;

  late final AnimationController _celebrationController;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final rng = math.Random();
    _particles = List.generate(42, (_) => _ConfettiParticle(rng));
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_loading || _confirmed) return;
    setState(() => _loading = true);

    try {
      HapticFeedback.mediumImpact();
      await widget.onConfirm();

      if (!mounted) return;
      setState(() {
        _loading = false;
        _confirmed = true;
      });

      HapticFeedback.heavyImpact();
      SoundService.instance.playTaskDone();
      _celebrationController.forward();

      await Future.delayed(const Duration(milliseconds: 1250));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: math.min(MediaQuery.of(context).size.width - 48, 360),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: nec.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : nec.separator.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_confirmed)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _celebrationController,
                    builder: (context, _) => CustomPaint(
                      painter: _ConfettiPainter(
                        progress: _celebrationController.value,
                        particles: _particles,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: _confirmed
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: _buildConfirmationView(nec, isDark),
                  secondChild: _buildCelebrationView(nec),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationView(NecColors nec, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.checkmark_alt,
              color: AppColors.success,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Mark as Done?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: nec.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Are you sure you want to complete this task?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: nec.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.taskTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: nec.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: nec.separator.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: nec.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Yes, Done',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCelebrationView(NecColors nec) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _celebrationController,
            curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
          ),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34C759), Color(0xFF30D158)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.checkmark,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Task Completed! 🎉',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: nec.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Great job! Moving to Completed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _ConfettiParticle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double spin;

  _ConfettiParticle(math.Random rng)
      : angle = rng.nextDouble() * 2 * math.pi,
        distance = 60 + rng.nextDouble() * 110,
        size = 4 + rng.nextDouble() * 6,
        spin = (rng.nextDouble() - 0.5) * 8,
        color = const [
          Color(0xFF34C759),
          Color(0xFF5856D6),
          Color(0xFFFF9500),
          Color(0xFF007AFF),
          Color(0xFFFF2D55),
          Color(0xFF30B0C7),
          Color(0xFFFFD60A),
        ][rng.nextInt(7)];
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height * 0.35);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final currentDist = p.distance * Curves.easeOutCubic.transform(progress);
      final x = center.dx + currentDist * math.cos(p.angle);
      final y = center.dy +
          currentDist * math.sin(p.angle) +
          (progress * progress * 35);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.7,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
