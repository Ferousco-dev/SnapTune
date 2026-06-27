import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../gallery/data/models/media_item_model.dart';
import '../../../gallery/domain/entities/media_item.dart';
import '../../data/services/history_service.dart';
import '../../domain/entities/optimization_record.dart';
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

  // History state
  List<OptimizationRecord> _history = [];

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
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final records = await HistoryService.instance.load();
    if (!mounted) return;
    setState(() => _history = records);
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

                // Savings summary + recent history
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SavingsSummaryCard(records: _history, isDark: isDark),
                  const SizedBox(height: AppSpacing.md),
                  _RecentHistoryList(
                    records: _history.take(5).toList(),
                    isDark: isDark,
                    onSeeAll: () => context.push(Routes.history),
                    onShare: (record) async {
                      final path = record.savedOutputPath;
                      if (path != null && File(path).existsSync()) {
                        await Share.shareXFiles([XFile(path)]);
                      }
                    },
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
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

// ── Savings summary card ──────────────────────────────────────────────────────

class _SavingsSummaryCard extends StatelessWidget {
  final List<OptimizationRecord> records;
  final bool isDark;

  const _SavingsSummaryCard({required this.records, required this.isDark});

  String _fmtBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final totalSaved = HistoryService.totalSavingsBytes(records);
    final sevenDay = HistoryService.dailySavings(records, 7);
    final best = HistoryService.bestPresetName(records);
    final recentCount = records.where((r) {
      final diff = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(r.timestampMs))
          .inDays;
      return diff < 7;
    }).length;

    final maxBucket = sevenDay.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
                'Savings',
                style: AppTypography.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Last 7 days',
                  style: AppTypography.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtBytes(totalSaved),
                style: AppTypography.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkOnSurface
                      : AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'saved · $recentCount files',
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkMuted
                        : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          if (best != null) ...[
            const SizedBox(height: 4),
            Text(
              'Best: $best',
              style: AppTypography.dmSans(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Sparkline — 7 day bar chart
          SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = sevenDay[i];
                final frac =
                    maxBucket > 0 ? (val / maxBucket).clamp(0.0, 1.0) : 0.0;
                final isToday = i == 6;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 60),
                          curve: Curves.easeOut,
                          height: frac > 0 ? (frac * 32).clamp(3.0, 32.0) : 3,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.primary.withAlpha(
                                    isDark ? 80 : 60),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7d ago',
                style: AppTypography.dmSans(
                    fontSize: 9,
                    color: isDark ? AppColors.darkMuted : AppColors.muted),
              ),
              Text(
                'Today',
                style: AppTypography.dmSans(
                    fontSize: 9,
                    color: isDark ? AppColors.darkMuted : AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recent history list ───────────────────────────────────────────────────────

class _RecentHistoryList extends StatelessWidget {
  final List<OptimizationRecord> records;
  final bool isDark;
  final VoidCallback onSeeAll;
  final void Function(OptimizationRecord) onShare;

  const _RecentHistoryList({
    required this.records,
    required this.isDark,
    required this.onSeeAll,
    required this.onShare,
  });

  String _fmtBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Recent',
              style: AppTypography.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: AppTypography.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkOutline : AppColors.outline,
              width: 0.5,
            ),
          ),
          child: Column(
            children: List.generate(records.length, (i) {
              final r = records[i];
              final isLast = i == records.length - 1;
              final hasSavings = r.savingsBytes > 0;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        // File type icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (r.isVideo
                                    ? const Color(0xFF7B61FF)
                                    : AppColors.primary)
                                .withAlpha(isDark ? 40 : 25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            r.isVideo
                                ? Icons.videocam_rounded
                                : Icons.image_rounded,
                            size: 18,
                            color: r.isVideo
                                ? const Color(0xFF7B61FF)
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + preset
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.filename.isEmpty ? 'Media file' : r.filename,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${r.presetName} · '
                                '${_fmtBytes(r.originalSizeBytes)} → '
                                '${_fmtBytes(r.outputSizeBytes)}',
                                style: AppTypography.dmSans(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Savings badge
                        if (hasSavings)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${r.savingsPct.toStringAsFixed(0)}%',
                              style: AppTypography.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF34C759),
                              ),
                            ),
                          ),
                        // Share button — only if path exists
                        if (r.savedOutputPath != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => onShare(r),
                            child: Icon(
                              Icons.ios_share_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 62,
                      color: isDark
                          ? AppColors.darkOutline
                          : AppColors.outline,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
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
