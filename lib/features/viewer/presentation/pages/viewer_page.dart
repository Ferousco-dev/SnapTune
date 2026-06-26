import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../gallery/domain/entities/media_item.dart';
import '../../../optimize/presentation/pages/optimize_page.dart'
    show ProcessingArgs;
import '../../../optimize/domain/entities/platform_preset.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.args.startIndex;
    _pageController = PageController(initialPage: widget.args.startIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleOverlays() =>
      setState(() => _overlaysVisible = !_overlaysVisible);

  List<MediaItem> get _items => widget.args.items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Page view — GestureDetector wraps it so taps toggle overlays
          // without blocking horizontal swipe
          GestureDetector(
            onTap: _toggleOverlays,
            behavior: HitTestBehavior.opaque,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, i) => _PhotoViewer(item: _items[i]),
            ),
          ),

          // Top overlay — Positioned directly in Stack, AnimatedOpacity handles fade
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
              ),
            ),
          ),

          // Bottom overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _overlaysVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: _BottomBar(item: _items[_currentIndex]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  final MediaItem item;
  const _PhotoViewer({required this.item});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
        ),
      );
    }

    if (_bytes == null) {
      return const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 48),
      );
    }

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.memory(_bytes!, fit: BoxFit.contain, gaplessPlayback: true),
            if (widget.item.isVideo)
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 36),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int currentIndex;
  final int total;

  const _TopBar({required this.currentIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.viewerTopGradient),
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
          _OverlayBtn(icon: Icons.favorite_border_rounded, onTap: () {}),
          const SizedBox(width: 4),
          _OverlayBtn(icon: Icons.more_vert_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final MediaItem item;
  const _BottomBar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.viewerBottomGradient),
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
                item.isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
                color: Colors.white60,
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(item.createDate),
                style: AppTypography.dmSans(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push(
              Routes.processing,
              extra: ProcessingArgs(
                item: item,
                preset: PlatformPreset.all.first,
              ),
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

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
