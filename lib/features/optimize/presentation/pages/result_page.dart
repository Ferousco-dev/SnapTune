import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../gallery/domain/entities/media_item.dart';
import '../../domain/entities/platform_preset.dart';

class ResultArgs {
  final PlatformPreset preset;
  final MediaItem? item;
  final Uint8List? outputBytes;
  final int originalSizeBytes;
  final bool bypassed;
  // Video output: one path per clip (multiple when Status Splitter fires)
  final List<String>? videoPaths;
  const ResultArgs({
    required this.preset,
    this.item,
    this.outputBytes,
    this.originalSizeBytes = 0,
    this.bypassed = false,
    this.videoPaths,
  });
}

class ResultPage extends StatefulWidget {
  final ResultArgs? args;
  const ResultPage({super.key, this.args});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  bool _sharing = false;
  bool _saving = false;
  final _shareButtonKey = GlobalKey();

  // Before/After slider — only used for image results
  Uint8List? _originalThumb;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _entryController.forward();
    _loadOriginalThumb();
  }

  Future<void> _loadOriginalThumb() async {
    final item = widget.args?.item;
    if (item == null || widget.args?.outputBytes == null) return;
    if (widget.args?.videoPaths != null) return; // video — no slider
    try {
      final asset = await AssetEntity.fromId(item.id);
      final thumb = await asset?.thumbnailDataWithSize(
        const ThumbnailSize.square(800),
        format: ThumbnailFormat.jpeg,
        quality: 95,
      );
      if (thumb != null && mounted) setState(() => _originalThumb = thumb);
    } catch (_) {}
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  bool get _isVideo => widget.args?.videoPaths != null;
  bool get _isMultiClip => (_isVideo) && (widget.args!.videoPaths!.length > 1);

  String get _sizeReductionLabel {
    if (widget.args?.bypassed == true) return '0%';
    final orig = widget.args?.originalSizeBytes ?? 0;
    if (orig == 0) return '—';
    if (_isVideo) {
      final paths = widget.args!.videoPaths!;
      final outSize = paths.fold<int>(
        0, (s, p) => s + (File(p).existsSync() ? File(p).lengthSync() : 0));
      final pct = ((1 - outSize / orig) * 100).round();
      return pct > 0 ? '$pct%' : '0%';
    }
    final out = widget.args?.outputBytes;
    if (out == null) return '—';
    final pct = ((1 - out.length / orig) * 100).round();
    return pct > 0 ? '$pct%' : '0%';
  }

  String get _qualityLabel {
    if (_isVideo) return 'H.264';
    final q = widget.args?.preset.jpegQuality ?? 85;
    final score = 92 + ((q - 80) / 20 * 7).round().clamp(0, 7);
    return '$score';
  }

  Future<File?> _outputFile() async {
    final bytes = widget.args?.outputBytes;
    if (bytes == null) return null;
    final tmp = await getTemporaryDirectory();
    final preset = widget.args?.preset;
    final name = preset != null
        ? 'snaptune_${preset.name.toLowerCase().replaceAll(' ', '_')}.jpg'
        : 'snaptune_optimized.jpg';
    final file = File('${tmp.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _shareNow({String? singleVideoPath}) async {
    setState(() => _sharing = true);
    try {
      final box = _shareButtonKey.currentContext?.findRenderObject()
          as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 400, 100, 50);

      if (_isVideo) {
        final paths = singleVideoPath != null
            ? [singleVideoPath]
            : widget.args!.videoPaths!;
        final xFiles = paths
            .where((p) => File(p).existsSync())
            .map((p) => XFile(p))
            .toList();
        if (xFiles.isEmpty || !mounted) return;
        await Share.shareXFiles(xFiles, sharePositionOrigin: origin);
        return;
      }

      File? file = await _outputFile();
      if (file == null && widget.args?.item != null) {
        final asset = await AssetEntity.fromId(widget.args!.item!.id);
        file = await asset?.file;
      }
      if (file == null || !mounted) return;
      await Share.shareXFiles([XFile(file.path)], sharePositionOrigin: origin);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _saveCopy() async {
    setState(() => _saving = true);
    try {
      if (_isVideo) {
        final paths = widget.args!.videoPaths!
            .where((p) => File(p).existsSync())
            .toList();
        for (int i = 0; i < paths.length; i++) {
          await PhotoManager.editor.saveVideo(
            File(paths[i]),
            title: paths.length > 1 ? 'SnapTune Clip ${i + 1}' : 'SnapTune',
          );
        }
      } else {
        final bytes = widget.args?.outputBytes;
        if (bytes != null) {
          final preset = widget.args?.preset;
          final name = preset != null
              ? 'snaptune_${preset.name.toLowerCase().replaceAll(' ', '_')}.jpg'
              : 'snaptune_optimized.jpg';
          await PhotoManager.editor.saveImage(
            bytes,
            filename: name,
            title: 'SnapTune',
          );
        } else if (widget.args?.item != null) {
          final asset = await AssetEntity.fromId(widget.args!.item!.id);
          final orig = await asset?.originBytes;
          if (orig != null) {
            await PhotoManager.editor.saveImage(
              orig,
              filename: 'snaptune_optimized.jpg',
              title: 'SnapTune',
            );
          }
        } else {
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isVideo && _isMultiClip
              ? 'All clips saved to your gallery'
              : 'Saved to your gallery'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preset = widget.args?.preset ?? PlatformPreset.all.first;

    final showSlider = !_isVideo &&
        _originalThumb != null &&
        widget.args?.outputBytes != null;

    final origBytes = widget.args?.originalSizeBytes ?? 0;
    final outBytes = _isVideo
        ? (widget.args?.videoPaths?.fold<int>(
                0,
                (s, p) =>
                    s + (File(p).existsSync() ? File(p).lengthSync() : 0)) ??
            0)
        : (widget.args?.outputBytes?.length ?? origBytes);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — back arrow + platform name + ready badge
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: preset.color.withAlpha(isDark ? 45 : 28),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(preset.icon, color: preset.color, size: 15),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          preset.name,
                          style: AppTypography.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withAlpha(isDark ? 40 : 22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded,
                            color: Color(0xFF34C759), size: 13),
                        const SizedBox(width: 4),
                        Text(
                          widget.args?.bypassed == true
                              ? 'Already optimal'
                              : _isMultiClip
                                  ? '${widget.args!.videoPaths!.length} clips'
                                  : 'Ready',
                          style: AppTypography.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF34C759),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

            // Before/After slider — image results only
            if (showSlider) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _BeforeAfterSlider(
                    before: _originalThumb!,
                    after: widget.args!.outputBytes!,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              const SizedBox(height: 12),
            ],

            // Size comparison row
            if (origBytes > 0)
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: _SizeCompareRow(
                    isDark: isDark,
                    originalBytes: origBytes,
                    outputBytes: outBytes,
                    bypassed: widget.args?.bypassed == true,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Stats row
            FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    _StatCard(
                      isDark: isDark,
                      label: 'Size saved',
                      value: _sizeReductionLabel,
                      icon: Icons.compress_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      isDark: isDark,
                      label: _isVideo ? 'Codec' : 'Quality',
                      value: _qualityLabel,
                      icon: _isVideo
                          ? Icons.videocam_rounded
                          : Icons.hd_rounded,
                      color: preset.color,
                    ),
                  ],
                ),
              ),
            ),

            // Multi-clip list
            if (_isMultiClip) ...[
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Post in order — each clip is under 29 seconds',
                          style: AppTypography.dmSans(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ...List.generate(
                        widget.args!.videoPaths!.length,
                        (i) {
                          final path = widget.args!.videoPaths![i];
                          final size = File(path).existsSync()
                              ? File(path).lengthSync()
                              : 0;
                          final sizeMb =
                              (size / (1024 * 1024)).toStringAsFixed(1);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkOutline
                                    : AppColors.outline,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: preset.color
                                        .withAlpha(isDark ? 40 : 25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: AppTypography.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: preset.color,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Clip ${i + 1}',
                                        style: AppTypography.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      Text(
                                        '$sizeMb MB · max 29s',
                                        style: AppTypography.dmSans(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _shareNow(singleVideoPath: path),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: preset.color
                                          .withAlpha(isDark ? 40 : 25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Share',
                                      style: AppTypography.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: preset.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Action buttons — pinned outside scroll so always visible
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                8,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              child: Column(
                children: [
                  // Share Now
                  GestureDetector(
                    key: _shareButtonKey,
                    onTap: _sharing ? null : _shareNow,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _sharing
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(70),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_sharing)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(Icons.share_rounded,
                                color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _sharing
                                ? 'Preparing...'
                                : _isMultiClip
                                    ? 'Share All Clips'
                                    : 'Share Now',
                            style: AppTypography.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Save Copy
                  GestureDetector(
                    onTap: _saving ? null : _saveCopy,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutline
                              : AppColors.outline,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_saving)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            )
                          else
                            Icon(
                              Icons.save_alt_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _saving ? 'Saving...' : 'Save Copy',
                            style: AppTypography.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeCompareRow extends StatelessWidget {
  final bool isDark;
  final int originalBytes;
  final int outputBytes;
  final bool bypassed;

  const _SizeCompareRow({
    required this.isDark,
    required this.originalBytes,
    required this.outputBytes,
    required this.bypassed,
  });

  String _fmt(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final pct = originalBytes > 0
        ? ((1 - outputBytes / originalBytes) * 100).round()
        : 0;
    final saved = pct > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.outline,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Text(
            _fmt(originalBytes),
            style: AppTypography.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            _fmt(outputBytes),
            style: AppTypography.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (bypassed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(isDark ? 40 : 22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Already optimal',
                style: AppTypography.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            )
          else if (saved)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withAlpha(isDark ? 40 : 22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-$pct%',
                style: AppTypography.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF34C759),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.isDark,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTypography.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.dmSans(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _BeforeAfterSlider extends StatefulWidget {
  final Uint8List before;
  final Uint8List after;
  final bool isDark;

  const _BeforeAfterSlider({
    required this.before,
    required this.after,
    required this.isDark,
  });

  @override
  State<_BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<_BeforeAfterSlider> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const height = 260.0;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.globalPosition);
              setState(() {
                _split = (local.dx / box.size.width).clamp(0.05, 0.95);
              });
            },
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Before — full width underneath
                  Image.memory(
                    widget.before,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),

                  // After — clipped to right of divider
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerRight,
                      widthFactor: 1.0 - _split,
                      child: Image.memory(
                        widget.after,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),

                  // Divider line
                  Positioned(
                    left: width * _split - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.white,
                    ),
                  ),

                  // Drag handle
                  Positioned(
                    left: width * _split - 20,
                    top: height / 2 - 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.unfold_more_rounded,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                  ),

                  // BEFORE label
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _SliderLabel(text: 'BEFORE'),
                  ),

                  // AFTER label
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _SliderLabel(text: 'AFTER'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliderLabel extends StatelessWidget {
  final String text;
  const _SliderLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
