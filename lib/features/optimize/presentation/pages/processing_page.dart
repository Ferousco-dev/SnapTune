import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/services/history_service.dart';
import '../../data/services/video_processor.dart';
import '../../domain/entities/optimization_record.dart';
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

  int _stepIndex = 0;
  double _progress = 0.0;
  String? _errorMsg;

  static const _imageSteps = [
    'Reading file...',
    'Compressing...',
    'Encoding JPEG...',
    'Done',
  ];

  static const _videoSteps = [
    'Reading video...',
    'Transcoding H.264...',
    'Splitting clips...',
    'Done',
  ];

  List<String> get _steps =>
      widget.args?.item?.isVideo == true ? _videoSteps : _imageSteps;

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

    if (item?.isVideo == true) {
      _setStep(0, 0.05);
      try {
        final asset = await AssetEntity.fromId(item!.id);
        debugPrint('[PP] asset lookup id=${item.id} → ${asset == null ? "NULL" : "ok"}');

        // Try file first, then originFile as fallback (handles some Android paths)
        File? file = await asset?.file;
        if (file == null && asset != null) {
          debugPrint('[PP] file is null, trying originFile');
          file = await asset.originFile;
        }
        debugPrint('[PP] file path: ${file?.path ?? "NULL"}');

        if (file == null) {
          debugPrint('[PP] both file and originFile returned null — falling through to passthrough');
          _setStep(3, 1.0);
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          context.pushReplacement(
            Routes.result,
            extra: ResultArgs(preset: preset, item: item),
          );
          return;
        }

        final result = await VideoProcessor().process(
          inputPath: file.absolute.path,
          onProgress: (p) {
            if (!mounted) return;
            // Map 0→1 progress across steps 0→2
            final stepIndex = p < 0.1
                ? 0
                : p < 0.85
                    ? 1
                    : 2;
            _setStep(stepIndex, p);
          },
        );

        if (!mounted) return;
        _setStep(3, 1.0);
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        await HistoryService.instance.save(OptimizationRecord(
          id: const Uuid().v4(),
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          presetId: preset.id.name,
          presetName: preset.name,
          filename: item.title,
          originalSizeBytes: result.originalSizeBytes,
          outputSizeBytes: result.outputSizeBytes,
          isVideo: true,
          savedOutputPath:
              result.outputPaths.isNotEmpty ? result.outputPaths.first : null,
          clipCount: result.outputPaths.length,
        ));

        if (!mounted) return;
        context.pushReplacement(
          Routes.result,
          extra: ResultArgs(
            preset: preset,
            item: item,
            bypassed: result.bypassed,
            originalSizeBytes: result.originalSizeBytes,
            videoPaths: result.outputPaths,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorMsg = 'Video processing failed: $e');
      }
      return;
    }

    if (item == null) {
      _setStep(3, 1.0);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      context.pushReplacement(
        Routes.result,
        extra: ResultArgs(preset: preset),
      );
      return;
    }

    AssetEntity? asset;
    int originalSize = 0;
    try {
      asset = await AssetEntity.fromId(item.id);
      final file = await asset?.file;
      originalSize = await file?.length() ?? 0;
    } catch (_) {}

    if (asset == null) {
      _setStep(3, 1.0);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      context.pushReplacement(
        Routes.result,
        extra: ResultArgs(preset: preset, item: item),
      );
      return;
    }

    _setStep(1, 0.25);

    Uint8List? outputBytes;
    bool bypassed = false;
    try {
      final file = await asset.file;
      if (file != null) {
        // Bypass: already-JPEG within target dimensions and below ~quality-80 threshold.
        // ~380 KB/megapixel is the inflection point where re-encoding adds size, not saves it.
        final mimeType = asset.mimeType ?? '';
        final isJpeg = mimeType == 'image/jpeg' || mimeType == 'image/jpg';
        final fitsBox = asset.width <= preset.maxWidth && asset.height <= preset.maxHeight;
        final megapixels = (asset.width * asset.height) / 1_000_000.0;
        final alreadyConditioned = isJpeg &&
            fitsBox &&
            megapixels > 0 &&
            (originalSize / megapixels) < 380_000;

        if (alreadyConditioned) {
          outputBytes = await file.readAsBytes();
          bypassed = true;
        } else {
          // Native iOS/Android compression: handles HEIC/HEIF/ProRAW, hardware-accelerated
          final effectiveQuality =
              widget.args?.qualityOverride ?? preset.jpegQuality;
          outputBytes = await FlutterImageCompress.compressWithFile(
            file.absolute.path,
            minWidth: preset.maxWidth,
            minHeight: preset.maxHeight,
            quality: effectiveQuality,
            format: CompressFormat.jpeg,
            keepExif: false,
          );
          // Anti-bloat guard: serve original if compression produced a larger file
          if (outputBytes != null && outputBytes.length >= originalSize) {
            outputBytes = await file.readAsBytes();
            bypassed = true;
          }
        }
      }
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

    if (originalSize > 0) {
      await HistoryService.instance.save(OptimizationRecord(
        id: const Uuid().v4(),
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        presetId: preset.id.name,
        presetName: preset.name,
        filename: item.title,
        originalSizeBytes: originalSize,
        outputSizeBytes: outputBytes?.length ?? originalSize,
        isVideo: false,
      ));
    }

    if (!mounted) return;
    context.pushReplacement(
      Routes.result,
      extra: ResultArgs(
        preset: preset,
        item: item,
        outputBytes: outputBytes,
        originalSizeBytes: originalSize,
        bypassed: bypassed,
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
                    'Processing failed',
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
