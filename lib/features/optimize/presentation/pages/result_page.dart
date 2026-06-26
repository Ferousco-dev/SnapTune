import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/router/routes.dart';
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
  const ResultArgs({
    required this.preset,
    this.item,
    this.outputBytes,  // Uint8List from optimization engine
    this.originalSizeBytes = 0,
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
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _sharing = false;
  bool _saving = false;
  final _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  String get _sizeReductionLabel {
    final out = widget.args?.outputBytes;
    final orig = widget.args?.originalSizeBytes ?? 0;
    if (out == null || orig == 0) return '—';
    final pct = ((1 - out.length / orig) * 100).round();
    return pct > 0 ? '$pct%' : '0%';
  }

  String get _qualityLabel {
    final q = widget.args?.preset.jpegQuality ?? 85;
    // Map quality 80-100 → score 92-99
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

  Future<void> _shareNow() async {
    setState(() => _sharing = true);
    try {
      File? file = await _outputFile();
      if (file == null && widget.args?.item != null) {
        final asset = await AssetEntity.fromId(widget.args!.item!.id);
        file = await asset?.file;
      }
      if (file == null || !mounted) return;

      final box = _shareButtonKey.currentContext?.findRenderObject()
          as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 400, 100, 50);

      await Share.shareXFiles(
        [XFile(file.path)],
        sharePositionOrigin: origin,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _saveCopy() async {
    setState(() => _saving = true);
    try {
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to your gallery'),
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
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => context.go(Routes.gallery),
                  ),
                  Expanded(
                    child: Text(
                      'Done',
                      style: AppTypography.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Success illustration
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: _SuccessIcon(preset: preset),
              ),
            ),

            const SizedBox(height: 28),

            // Title
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'All set!',
                style: AppTypography.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            const SizedBox(height: 8),

            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'Optimized for ${preset.name}',
                style: AppTypography.dmSans(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Stats row
            FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    _StatCard(
                      isDark: isDark,
                      label: 'Size reduction',
                      value: _sizeReductionLabel,
                      icon: Icons.compress_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      isDark: isDark,
                      label: 'Quality score',
                      value: _qualityLabel,
                      icon: Icons.stars_rounded,
                      color: AppColors.violet,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Action buttons
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
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
                            _sharing ? 'Preparing...' : 'Share Now',
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
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

class _SuccessIcon extends StatelessWidget {
  final PlatformPreset preset;
  const _SuccessIcon({required this.preset});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(80),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
        ),
        Positioned(
          bottom: -10,
          right: -10,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: preset.color.withAlpha(isDark ? 50 : 30),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBackground : AppColors.background,
                width: 3,
              ),
            ),
            child: Icon(preset.icon, color: preset.color, size: 20),
          ),
        ),
      ],
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
