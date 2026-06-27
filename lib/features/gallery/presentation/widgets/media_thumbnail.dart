import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/media_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class MediaThumbnail extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelecting;

  const MediaThumbnail({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: RepaintBoundary(
        child: Stack(
        fit: StackFit.expand,
        children: [
          // Stable key prevents State disposal when selection changes
          _ThumbnailImage(key: ValueKey(item.id), id: item.id),

          // Video overlay (duration + play icon)
          if (item.isVideo) _VideoOverlay(duration: item.duration),

          // Selection overlay
          AnimatedOpacity(
            opacity: isSelected ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              color: AppColors.primary.withAlpha(80),
            ),
          ),

          // Selection checkmark
          Positioned(
            top: 6,
            right: 6,
            child: AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.elasticOut,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),

          // Empty circle shown when in select mode but this item is not selected
          if (isSelecting && !isSelected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withAlpha(60),
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _ThumbnailImage extends StatefulWidget {
  final String id;
  const _ThumbnailImage({super.key, required this.id});

  @override
  State<_ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends State<_ThumbnailImage> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final asset = await AssetEntity.fromId(widget.id);
    if (asset == null || !mounted) return;
    final bytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
      quality: 85,
    );
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    if (_loading) return Container(color: shimmerColor);

    if (_bytes == null) {
      return Container(
        color: shimmerColor,
        child: const Icon(Icons.broken_image_rounded,
            color: Colors.white38, size: 20),
      );
    }

    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 200,
      cacheHeight: 200,
    );
  }
}

class _VideoOverlay extends StatelessWidget {
  final int duration;
  const _VideoOverlay({required this.duration});

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: const BoxDecoration(
          gradient: AppColors.viewerBottomGradient,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.play_circle_fill_rounded,
                color: Colors.white, size: 13),
            Text(
              _formatDuration(duration),
              style: AppTypography.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
