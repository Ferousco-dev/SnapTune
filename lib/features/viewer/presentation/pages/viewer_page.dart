import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/liked_ids_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../gallery/domain/entities/media_item.dart';
import '../../../optimize/presentation/pages/optimize_page.dart'
    show OptimizeArgs;

class ViewerArgs {
  final List<MediaItem> items;
  final int startIndex;
  const ViewerArgs({required this.items, required this.startIndex});
}

class ViewerPage extends StatefulWidget {
  final ViewerArgs args;
  const ViewerPage({super.key, required this.args});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _overlaysVisible = true;
  bool _photoZoomed = false;

  // Swipe-down-to-dismiss state
  double _dragOffset = 0.0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.args.startIndex;
    _pageController = PageController(initialPage: widget.args.startIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    sl<LikedIdsNotifier>().addListener(_onLikesChanged);
  }

  void _onLikesChanged() => setState(() {});

  @override
  void dispose() {
    sl<LikedIdsNotifier>().removeListener(_onLikesChanged);
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleOverlays() =>
      setState(() => _overlaysVisible = !_overlaysVisible);

  void _toggleLike(String id) {
    final wasLiked = sl<LikedIdsNotifier>().isLiked(id);
    if (!wasLiked) HapticFeedback.lightImpact();
    sl<LikedIdsNotifier>().toggle(id);
  }

  void _showOptions(MediaItem item) {
    HapticFeedback.selectionClick();
    final pageCtx = context;
    showModalBottomSheet(
      context: pageCtx,
      backgroundColor: Colors.transparent,
      builder: (_) => _ViewerOptionsSheet(item: item, pageContext: pageCtx),
    );
  }

  void _onDragStart(DragStartDetails _) {
    if (_photoZoomed) return;
    _dragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > 120 || velocity > 800) {
      context.pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  List<MediaItem> get _items => widget.args.items;

  @override
  Widget build(BuildContext context) {
    final currentItem = _items[_currentIndex];
    final dragProgress = (_dragOffset.abs() / 300).clamp(0.0, 1.0);
    final dismissOpacity = 1.0 - dragProgress;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Opacity(
          opacity: dismissOpacity.clamp(0.0, 1.0),
          child: Stack(
            children: [
              GestureDetector(
                onTap: _toggleOverlays,
                onVerticalDragStart: _onDragStart,
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                behavior: HitTestBehavior.opaque,
                child: PageView.builder(
                    controller: _pageController,
                    physics: _photoZoomed
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: _items.length,
                    onPageChanged: (i) => setState(() {
                      _currentIndex = i;
                      _photoZoomed = false;
                    }),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return item.isVideo
                          ? _VideoViewer(item: item)
                          : _PhotoViewer(
                              item: item,
                              onZoomChanged: (zoomed) {
                                if (_photoZoomed != zoomed) {
                                  setState(() => _photoZoomed = zoomed);
                                }
                              },
                            );
                    },
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _overlaysVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: _TopBar(
                      currentIndex: _currentIndex,
                      total: _items.length,
                      isLiked:
                          sl<LikedIdsNotifier>().isLiked(currentItem.id),
                      onLikeTap: () => _toggleLike(currentItem.id),
                      onMoreTap: () => _showOptions(currentItem),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _overlaysVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: _BottomBar(item: currentItem),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Photo viewer ──────────────────────────────────────────────────────────────

class _PhotoViewer extends StatefulWidget {
  final MediaItem item;
  final void Function(bool isZoomed)? onZoomChanged;
  const _PhotoViewer({required this.item, this.onZoomChanged});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  Uint8List? _bytes;
  bool _loading = true;
  final _transformCtrl = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _wasZoomed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _transformCtrl.addListener(_onTransform);
  }

  void _onTransform() {
    final zoomed = _transformCtrl.value.getMaxScaleOnAxis() > 1.05;
    if (zoomed != _wasZoomed) {
      _wasZoomed = zoomed;
      widget.onZoomChanged?.call(zoomed);
    }
  }

  @override
  void dispose() {
    _transformCtrl.removeListener(_onTransform);
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final asset = await AssetEntity.fromId(widget.item.id);
    if (asset == null || !mounted) return;
    final bytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1080, 1920),
      quality: 95,
    );
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _onDoubleTap() {
    if (_wasZoomed) {
      _transformCtrl.value = Matrix4.identity();
      return;
    }
    const scale = 2.5;
    final pos = _doubleTapDetails!.localPosition;
    final size = context.size ?? const Size(390, 844);
    // Translate so the tap point lands at the viewport center after scaling
    final dx = size.width / 2 - pos.dx * scale;
    final dy = size.height / 2 - pos.dy * scale;
    _transformCtrl.value = Matrix4.translationValues(dx, dy, 0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white38),
        ),
      );
    }
    if (_bytes == null) {
      return const Center(
        child: Icon(Icons.broken_image_rounded,
            color: Colors.white30, size: 48),
      );
    }
    return GestureDetector(
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformCtrl,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: Image.memory(_bytes!, fit: BoxFit.contain, gaplessPlayback: true),
        ),
      ),
    );
  }
}

// ── Video viewer ──────────────────────────────────────────────────────────────

class _VideoViewer extends StatefulWidget {
  final MediaItem item;
  const _VideoViewer({required this.item});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  Uint8List? _thumbnail;
  VideoPlayerController? _controller;
  bool _loadingThumb = true;
  bool _loadingVideo = false;
  double _volume = 1.0;
  bool _showVolume = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final asset = await AssetEntity.fromId(widget.item.id);
    if (asset == null || !mounted) return;
    final bytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1080, 1920),
      quality: 90,
    );
    if (!mounted) return;
    setState(() {
      _thumbnail = bytes;
      _loadingThumb = false;
    });
  }

  Future<void> _initAndPlay() async {
    if (_controller != null || _loadingVideo) return;
    setState(() => _loadingVideo = true);
    try {
      final asset = await AssetEntity.fromId(widget.item.id);
      final file = await asset?.file;
      if (file == null || !mounted) return;
      final ctrl = VideoPlayerController.file(file);
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      ctrl.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() {
        _controller = ctrl;
        _loadingVideo = false;
      });
      ctrl.play();
    } catch (_) {
      if (mounted) setState(() => _loadingVideo = false);
    }
  }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
    setState(() {});
  }

  void _setVolume(double v) {
    _volume = v;
    _controller?.setVolume(v);
    setState(() {});
  }

  void _toggleVolumeSlider() =>
      setState(() => _showVolume = !_showVolume);

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;

    if (ctrl != null && ctrl.value.isInitialized) {
      return GestureDetector(
        onTap: _togglePlayPause,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: ctrl.value.aspectRatio,
                child: VideoPlayer(ctrl),
              ),

              // Play/pause overlay
              if (!ctrl.value.isPlaying)
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white38, width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 40),
                ),

              // Progress bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  ctrl,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 0, vertical: 4),
                  colors: const VideoProgressColors(
                    playedColor: AppColors.primary,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),

              // Duration label
              Positioned(
                bottom: 16,
                right: 48,
                child: Text(
                  _formatDuration(
                      ctrl.value.position, ctrl.value.duration),
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              // Volume toggle button
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _toggleVolumeSlider,
                  child: Icon(
                    _volume == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),

              // Volume slider (shown on demand)
              if (_showVolume)
                Positioned(
                  bottom: 36,
                  right: 0,
                  child: SizedBox(
                    height: 140,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: _volume,
                        onChanged: _setVolume,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Thumbnail + play button (before video is loaded)
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!_loadingThumb && _thumbnail != null)
              Image.memory(_thumbnail!, fit: BoxFit.contain,
                  gaplessPlayback: true)
            else
              Container(color: Colors.black),

            GestureDetector(
              onTap: _initAndPlay,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white38, width: 1.5),
                ),
                child: _loadingVideo
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration pos, Duration total) {
    String fmt(Duration d) =>
        '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return '${fmt(pos)} / ${fmt(total)}';
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onMoreTap;

  const _TopBar({
    required this.currentIndex,
    required this.total,
    required this.isLiked,
    required this.onLikeTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          const BoxDecoration(gradient: AppColors.viewerTopGradient),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 4,
        right: 12,
        bottom: 32,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              '${currentIndex + 1} of $total',
              textAlign: TextAlign.center,
              style: AppTypography.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: onLikeTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                      CurvedAnimation(
                          parent: animation, curve: Curves.elasticOut),
                    ),
                    child: child,
                  ),
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(isLiked),
                    color: isLiked ? AppColors.coral : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onMoreTap,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.more_vert_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final MediaItem item;
  const _BottomBar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          const BoxDecoration(gradient: AppColors.viewerBottomGradient),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.isVideo
                    ? Icons.videocam_rounded
                    : Icons.photo_rounded,
                color: Colors.white60,
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(item.createDate),
                style: AppTypography.dmSans(
                    fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push(
              Routes.optimizeItem,
              extra: OptimizeArgs(item: item),
            ),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_fix_high_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Optimize & Share',
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
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Viewer options sheet ──────────────────────────────────────────────────────

class _ViewerOptionsSheet extends StatelessWidget {
  final MediaItem item;
  // Page-level context - stays valid after this sheet is dismissed
  final BuildContext pageContext;

  const _ViewerOptionsSheet({
    required this.item,
    required this.pageContext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.darkOutline : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _InfoRow(item: item, isDark: isDark),
          ),

          const SizedBox(height: 8),
          _Divider(isDark: isDark),

          _SheetOption(
            icon: Icons.info_outline_rounded,
            label: 'Details',
            isDark: isDark,
            onTap: () {
              // Pop this sheet first using its own context (still valid here)
              Navigator.pop(context);
              // Then show details sheet using the page context (never deactivated)
              showModalBottomSheet(
                context: pageContext,
                backgroundColor: Colors.transparent,
                builder: (_) => _DetailsSheet(item: item),
              );
            },
          ),
          _SheetOption(
            icon: Icons.share_rounded,
            label: 'Share original',
            isDark: isDark,
            onTap: () async {
              Navigator.pop(context);
              try {
                final asset = await AssetEntity.fromId(item.id);
                final file = await asset?.file;
                if (file == null) return;
                await Share.shareXFiles([XFile(file.path)]);
              } catch (_) {}
            },
          ),

          _Divider(isDark: isDark),

          _SheetOption(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            isDark: isDark,
            isDestructive: true,
            onTap: () async {
              Navigator.pop(context);
              if (!pageContext.mounted) return;
              final confirmed = await showDialog<bool>(
                context: pageContext,
                builder: (_) => _ViewerDeleteDialog(),
              );
              if (confirmed != true || !pageContext.mounted) return;
              try {
                await PhotoManager.editor.deleteWithIds([item.id]);
              } catch (_) {}
              if (pageContext.mounted) GoRouter.of(pageContext).pop();
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ── Delete dialog ─────────────────────────────────────────────────────────────

class _ViewerDeleteDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(isDark ? 35 : 20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete photo?',
              style: AppTypography.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will permanently remove the photo from your library.',
              style: AppTypography.dmSans(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: AppTypography.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Delete',
                          style: AppTypography.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Details sheet ─────────────────────────────────────────────────────────────

class _DetailsSheet extends StatefulWidget {
  final MediaItem item;
  const _DetailsSheet({required this.item});

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  int? _fileSizeBytes;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final asset = await AssetEntity.fromId(widget.item.id);
      if (asset == null || !mounted) return;
      final file = await asset.file;
      if (file != null && mounted) {
        final size = await File(file.path).length();
        if (mounted) setState(() => _fileSizeBytes = size);
      }
      final lat = asset.latitude;
      final lng = asset.longitude;
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0 && mounted) {
        setState(() {
          _latitude = lat;
          _longitude = lng;
        });
      }
    } catch (_) {}
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkOutline : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Details',
            style: AppTypography.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _DetailRow(
            icon: item.isVideo
                ? Icons.videocam_rounded
                : Icons.photo_rounded,
            label: 'Type',
            value: item.isVideo ? 'Video' : 'Photo',
            isDark: isDark,
          ),
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(item.createDate),
            isDark: isDark,
          ),
          if (item.width > 0 && item.height > 0)
            _DetailRow(
              icon: Icons.aspect_ratio_rounded,
              label: 'Dimensions',
              value: '${item.width} x ${item.height}',
              isDark: isDark,
            ),
          if (item.isVideo && item.duration > 0)
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: _formatDuration(item.duration),
              isDark: isDark,
            ),
          _DetailRow(
            icon: Icons.storage_rounded,
            label: 'File size',
            value: _fileSizeBytes != null
                ? _formatSize(_fileSizeBytes!)
                : '...',
            isDark: isDark,
            isLoading: _fileSizeBytes == null,
          ),
          if (_latitude != null && _longitude != null)
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value:
                  '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
              isDark: isDark,
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ── Shared sheet widgets ──────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final MediaItem item;
  final bool isDark;
  const _InfoRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.isVideo ? 'Video' : 'Photo',
              style: AppTypography.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _shortDate(item.createDate),
              style: AppTypography.dmSans(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _shortDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool isLoading;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Text(
              value,
              style: AppTypography.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTypography.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
    );
  }
}
