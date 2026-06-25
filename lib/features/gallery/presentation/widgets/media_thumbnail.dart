import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/media_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class MediaThumbnail extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onTap;

  const MediaThumbnail({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ThumbnailImage(id: item.id),
          if (item.isVideo) _VideoOverlay(duration: item.duration),
        ],
      ),
    );
  }
}

class _ThumbnailImage extends StatefulWidget {
  final String id;
  const _ThumbnailImage({required this.id});

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
    final bytes = await asset.thumbnailDataWithSize(const ThumbnailSize(300, 300));
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    if (_loading) {
      return Container(color: shimmerColor);
    }

    if (_bytes == null) {
      return Container(
        color: shimmerColor,
        child: const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 20),
      );
    }

    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
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
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
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
