import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/platform_preset.dart';
import 'optimize_page.dart';
import 'result_page.dart';

class ProcessingPage extends StatefulWidget {
  final ProcessingArgs? args;
  const ProcessingPage({super.key, this.args});

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _pulseController;
  late final AnimationController _stepController;

  int _stepIndex = 0;
  double _progress = 0.0;

  static const _steps = [
    'Analyzing media...',
    'Applying smart filters...',
    'Encoding output...',
    'Finalizing...',
  ];

  static const _stepDurations = [1400, 1800, 2200, 600];

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _stepController = AnimationController(vsync: this);

    _runSteps();
  }

  Future<void> _runSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() {
        _stepIndex = i;
        _progress = i / _steps.length;
      });

      await Future.delayed(Duration(milliseconds: _stepDurations[i]));
    }

    if (!mounted) return;
    setState(() => _progress = 1.0);

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    context.pushReplacement(
      Routes.result,
      extra: ResultArgs(
        preset: widget.args?.preset ?? PlatformPreset.all.first,
        item: widget.args?.item,
      ),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    _pulseController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preset = widget.args?.preset ?? PlatformPreset.all.first;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Optimizing',
                    style: AppTypography.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Animated ring + progress circle
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, _) => Container(
                      width: 180 + _pulseController.value * 16,
                      height: 180 + _pulseController.value * 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary
                              .withAlpha((40 * (1 - _pulseController.value)).toInt()),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // Progress arc
                  AnimatedBuilder(
                    animation: _ringController,
                    builder: (_, _) {
                      return CustomPaint(
                        size: const Size(160, 160),
                        painter: _ProgressArcPainter(
                          progress: _progress,
                          spinAngle: _ringController.value * 2 * math.pi,
                          color: AppColors.primary,
                          trackColor: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant,
                        ),
                      );
                    },
                  ),

                  // Center icon + percentage
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: preset.color.withAlpha(isDark ? 40 : 25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(preset.icon,
                            color: preset.color, size: 26),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, _) => Text(
                          '${(_progress * 100).toInt()}%',
                          style: AppTypography.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Step indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                _steps[_stepIndex],
                key: ValueKey(_stepIndex),
                style: AppTypography.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Step dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (i) {
                final active = i == _stepIndex;
                final done = i < _stepIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: done || active
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Platform label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: preset.color.withAlpha(isDark ? 35 : 20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(preset.icon, color: preset.color, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    preset.name,
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: preset.color,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final double spinAngle;
  final Color color;
  final Color trackColor;

  const _ProgressArcPainter({
    required this.progress,
    required this.spinAngle,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * progress,
        colors: [color.withAlpha(180), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Spinning leading dot
    if (progress < 1.0) {
      final dotAngle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ProgressArcPainter old) =>
      old.progress != progress || old.spinAngle != spinAngle;
}
