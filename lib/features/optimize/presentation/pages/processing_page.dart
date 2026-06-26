import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
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

// ── Isolate-safe task / result ────────────────────────────────────────────────

class _Task {
  final Uint8List inputBytes;
  final int maxWidth;
  final int maxHeight;
  final int jpegQuality;
  const _Task({
    required this.inputBytes,
    required this.maxWidth,
    required this.maxHeight,
    required this.jpegQuality,
  });
}

class _Result {
  final Uint8List outputBytes;
  final int originalSize;
  const _Result({required this.outputBytes, required this.originalSize});
}

// Top-level so compute() can send it to a background isolate
Future<_Result> _processImage(_Task task) async {
  final originalSize = task.inputBytes.length;

  // Telegram / lossless: skip re-encoding, just copy through
  if (task.maxWidth == 0 && task.maxHeight == 0 && task.jpegQuality == 100) {
    return _Result(outputBytes: task.inputBytes, originalSize: originalSize);
  }

  final decoded = img.decodeImage(task.inputBytes);
  if (decoded == null) {
    return _Result(outputBytes: task.inputBytes, originalSize: originalSize);
  }

  img.Image output = decoded;

  // Resize to fit within target bounds (scale down only)
  final tw = task.maxWidth > 0 ? task.maxWidth : decoded.width;
  final th = task.maxHeight > 0 ? task.maxHeight : decoded.height;
  final scaleX = tw / decoded.width;
  final scaleY = th / decoded.height;
  final scale = math.min(scaleX, scaleY);

  if (scale < 1.0) {
    output = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  final encoded = img.encodeJpg(output, quality: task.jpegQuality);
  return _Result(
    outputBytes: Uint8List.fromList(encoded),
    originalSize: originalSize,
  );
}

// ── Page ─────────────────────────────────────────────────────────────────────

class _ProcessingPageState extends State<ProcessingPage>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _pulseController;

  int _stepIndex = 0;
  double _progress = 0.0;
  String? _errorMsg;

  static const _steps = [
    'Analyzing media...',
    'Applying smart filters...',
    'Encoding output...',
    'Finalizing...',
  ];

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

    _run();
  }

  Future<void> _run() async {
    final item = widget.args?.item;
    final preset = widget.args?.preset ?? PlatformPreset.all.first;

    _setStep(0, 0.05);

    Uint8List? inputBytes;
    if (item != null) {
      try {
        final asset = await AssetEntity.fromId(item.id);
        inputBytes = await asset?.originBytes;
      } catch (_) {}
    }

    if (!mounted) return;

    if (inputBytes == null || item == null) {
      // No media: skip straight to result with no bytes
      _setStep(3, 1.0);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      context.pushReplacement(
        Routes.result,
        extra: ResultArgs(preset: preset),
      );
      return;
    }

    _setStep(1, 0.25);

    _Result result;
    try {
      result = await compute(
        _processImage,
        _Task(
          inputBytes: inputBytes,
          maxWidth: preset.maxWidth,
          maxHeight: preset.maxHeight,
          jpegQuality: preset.jpegQuality,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Processing failed: $e');
      return;
    }

    if (!mounted) return;
    _setStep(2, 0.75);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    _setStep(3, 1.0);
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    context.pushReplacement(
      Routes.result,
      extra: ResultArgs(
        preset: preset,
        item: item,
        outputBytes: result.outputBytes,
        originalSizeBytes: result.originalSize,
      ),
    );
  }

  void _setStep(int index, double progress) {
    if (!mounted) return;
    setState(() {
      _stepIndex = index;
      _progress = progress;
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preset = widget.args?.preset ?? PlatformPreset.all.first;

    if (_errorMsg != null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: AppTypography.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMsg!,
                    textAlign: TextAlign.center,
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.go(Routes.gallery),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Back to gallery',
                        style: AppTypography.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                          color: AppColors.primary.withAlpha(
                              (40 * (1 - _pulseController.value)).toInt()),
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
                        child: Icon(preset.icon, color: preset.color, size: 26),
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

            // Step label
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

    // Leading dot at the arc tip
    if (progress < 1.0) {
      final dotAngle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressArcPainter old) =>
      old.progress != progress || old.spinAngle != spinAngle;
}
