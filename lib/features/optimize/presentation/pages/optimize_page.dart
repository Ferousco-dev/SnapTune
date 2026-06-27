import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../gallery/data/models/media_item_model.dart';
import '../../../gallery/domain/entities/media_item.dart';
import '../../domain/entities/platform_preset.dart';

class OptimizeArgs {
  final MediaItem item;
  const OptimizeArgs({required this.item});
}

class OptimizePage extends StatefulWidget {
  final OptimizeArgs? args;
  const OptimizePage({super.key, this.args});

  @override
  State<OptimizePage> createState() => _OptimizePageState();
}

class _OptimizePageState extends State<OptimizePage> {
  PlatformId _selected = PlatformId.whatsapp;
  int _quality = 88; // mirrors the default preset quality, user-adjustable

  // Photo picker state — only used when args == null (tab opened directly)
  List<AssetEntity> _recentAssets = [];
  AssetEntity? _pickedAsset;
  bool _loadingAssets = false;

  PlatformPreset get _activePreset =>
      PlatformPreset.all.firstWhere((p) => p.id == _selected);

  bool get _hasPreSelected => widget.args != null;

  MediaItem? get _effectiveItem {
    if (_hasPreSelected) return widget.args!.item;
    if (_pickedAsset != null) return MediaItemModel.fromAsset(_pickedAsset!);
    return null;
  }

  bool get _canStart => _effectiveItem != null;

  @override
  void initState() {
    super.initState();
    _quality = _activePreset.jpegQuality;
    if (!_hasPreSelected) _loadRecents();
  }

  Future<void> _loadRecents() async {
    setState(() => _loadingAssets = true);
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // images + videos
        onlyAll: true,
      );
      if (albums.isEmpty || !mounted) return;
      final assets = await albums.first.getAssetListRange(start: 0, end: 40);
      if (!mounted) return;
      setState(() => _recentAssets = assets);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAssets = false);
    }
  }

  void _startOptimization() {
    if (!_canStart) return;
    context.push(
      Routes.processing,
      extra: ProcessingArgs(
        item: _effectiveItem,
        preset: _activePreset,
        qualityOverride: _quality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Optimize',
          style: AppTypography.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Photo picker — only shown when opened from the Optimize tab
                if (!_hasPreSelected) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppSpacing.sm, top: AppSpacing.xs),
                    child: Text(
                      'Choose a photo',
                      style: AppTypography.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  _PhotoPickerStrip(
                    isDark: isDark,
                    assets: _recentAssets,
                    loading: _loadingAssets,
                    selected: _pickedAsset,
                    onSelect: (asset) =>
                        setState(() => _pickedAsset = asset),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Section header
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppSpacing.sm, top: AppSpacing.xs),
                  child: Text(
                    'Choose a platform',
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // Platform cards
                ...PlatformPreset.all.map(
                  (preset) => _PlatformCard(
                    preset: preset,
                    isSelected: _selected == preset.id,
                    isDark: isDark,
                    onTap: () => setState(() {
                      _selected = preset.id;
                      _quality = preset.jpegQuality; // reset to platform default
                    }),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Quality slider
                _QualitySlider(
                  value: _quality,
                  defaultValue: _activePreset.jpegQuality,
                  isDark: isDark,
                  onChanged: (v) => setState(() => _quality = v),
                ),

                const SizedBox(height: AppSpacing.md),

                // Quality note
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SnapTune conditions your media so it survives platform compression with minimum visible loss.',
                          style: AppTypography.dmSans(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.onPrimaryContainer,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Start button
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _canStart ? 1.0 : 0.4,
              child: GestureDetector(
                onTap: _canStart ? _startOptimization : null,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _canStart
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(70),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_fix_high_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Start Optimization',
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
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo picker strip ────────────────────────────────────────────────────────

class _PhotoPickerStrip extends StatelessWidget {
  final bool isDark;
  final List<AssetEntity> assets;
  final bool loading;
  final AssetEntity? selected;
  final ValueChanged<AssetEntity> onSelect;

  const _PhotoPickerStrip({
    required this.isDark,
    required this.assets,
    required this.loading,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 88,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (assets.isEmpty) {
      return Container(
        height: 88,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            'No photos found',
            style: AppTypography.dmSans(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: assets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final asset = assets[index];
          final isSelected = selected?.id == asset.id;
          return GestureDetector(
            onTap: () => onSelect(asset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 80,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail — works for both images and videos
                    FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(
                          const ThumbnailSize.square(160)),
                      builder: (context, snap) {
                        if (snap.data == null) {
                          return Container(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.surfaceVariant,
                          );
                        }
                        return Image.memory(snap.data!, fit: BoxFit.cover);
                      },
                    ),

                    // Video indicator — play icon + duration
                    if (asset.type == AssetType.video) ...[
                      // Dark gradient at the bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withAlpha(180),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Play icon top-left
                      const Positioned(
                        top: 5,
                        left: 5,
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      // Duration bottom-right
                      Positioned(
                        bottom: 4,
                        right: 5,
                        child: Text(
                          _formatDuration(asset.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

                    // Selection overlay
                    if (isSelected)
                      Container(
                        color: AppColors.primary.withAlpha(60),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

// ── Platform card ─────────────────────────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  final PlatformPreset preset;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.preset,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.darkSurfaceSelected
                  : AppColors.surfaceSelected)
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkOutline : AppColors.outline),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Platform icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: preset.color.withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(preset.icon, color: preset.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: AppTypography.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.subtitle,
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.specs,
                    style: AppTypography.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: preset.color,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkMuted : AppColors.muted),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Args class used by ProcessingPage — defined here to avoid circular imports
class ProcessingArgs {
  final MediaItem? item;
  final PlatformPreset preset;
  final int? qualityOverride; // user-adjusted quality, overrides preset.jpegQuality
  const ProcessingArgs({
    required this.item,
    required this.preset,
    this.qualityOverride,
  });
}

// ── Quality slider ────────────────────────────────────────────────────────────

class _QualitySlider extends StatelessWidget {
  final int value;
  final int defaultValue;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _QualitySlider({
    required this.value,
    required this.defaultValue,
    required this.isDark,
    required this.onChanged,
  });

  String get _label {
    if (value <= 72) return 'Smaller file';
    if (value <= 84) return 'Balanced';
    if (value <= 92) return 'High quality';
    return 'Maximum';
  }

  Color get _labelColor {
    if (value <= 72) return const Color(0xFFFF9500);
    if (value <= 84) return const Color(0xFF34C759);
    if (value <= 92) return AppColors.primary;
    return const Color(0xFF7B61FF);
  }

  @override
  Widget build(BuildContext context) {
    final isModified = value != defaultValue;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
          Row(
            children: [
              Text(
                'Quality',
                style: AppTypography.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Quality badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _labelColor.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _label,
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Numeric value
              Text(
                '$value',
                style: AppTypography.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                ),
              ),
              // Reset button — only visible when modified
              if (isModified) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onChanged(defaultValue),
                  child: Text(
                    'Reset',
                    style: AppTypography.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor:
                  isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(30),
            ),
            child: Slider(
              min: 60,
              max: 100,
              divisions: 40,
              value: value.toDouble(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Smaller file',
                style: AppTypography.dmSans(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkMuted
                      : AppColors.muted,
                ),
              ),
              Text(
                'Sharper detail',
                style: AppTypography.dmSans(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkMuted
                      : AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
