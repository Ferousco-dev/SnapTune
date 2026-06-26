import 'dart:io';
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
import '../../../gallery/presentation/widgets/media_thumbnail.dart';
import '../../../viewer/presentation/pages/viewer_page.dart';

// Maps well-known album names to a sort priority (lower = first)
int _albumPriority(String name) {
  final n = name.toLowerCase().trim();
  if (n == 'camera roll' || n == 'recents' || n == 'camera' || n == 'dcim') return 0;
  if (n == 'screenshots' || n == 'screenshot') return 1;
  if (n.startsWith('whatsapp')) return 2;
  if (n.contains('instagram')) return 3;
  if (n == 'videos') return 4;
  if (n == 'selfies') return 5;
  if (n == 'favorites') return 6;
  if (n.contains('snapchat') || n.contains('telegram') || n.contains('twitter')) return 7;
  if (n.contains('tiktok')) return 8;
  if (n == 'live photos') return 9;
  return 50;
}

IconData _albumTypeIcon(String name) {
  final n = name.toLowerCase().trim();
  if (n == 'screenshots' || n == 'screenshot') return Icons.screenshot_monitor_rounded;
  if (n.startsWith('whatsapp')) return Icons.chat_bubble_rounded;
  if (n.contains('instagram')) return Icons.camera_alt_rounded;
  if (n == 'videos') return Icons.videocam_rounded;
  if (n == 'selfies') return Icons.face_rounded;
  if (n == 'favorites') return Icons.favorite_rounded;
  if (n == 'camera roll' || n == 'recents' || n == 'camera') return Icons.camera_rounded;
  if (n.contains('snapchat')) return Icons.wb_sunny_rounded;
  if (n.contains('telegram')) return Icons.send_rounded;
  if (n.contains('twitter') || n == 'x') return Icons.alternate_email_rounded;
  if (n.contains('tiktok')) return Icons.music_note_rounded;
  if (n == 'live photos') return Icons.motion_photos_on_rounded;
  if (n.contains('panorama') || n.contains('pano')) return Icons.panorama_rounded;
  if (n.contains('portrait')) return Icons.portrait_rounded;
  if (n.contains('slow')) return Icons.slow_motion_video_rounded;
  if (n.contains('burst')) return Icons.burst_mode_rounded;
  if (n.contains('download')) return Icons.download_rounded;
  return Icons.photo_album_outlined;
}

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _recentlyDeleted;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: false,
    );

    AssetPathEntity? recentlyDeleted;
    final candidates = <AssetPathEntity>[];
    for (final a in raw) {
      if (!a.isAll) {
        if (a.name.toLowerCase().contains('recently deleted')) {
          recentlyDeleted = a;
        } else {
          candidates.add(a);
        }
      }
    }

    final counted = await Future.wait(
      candidates.map((a) async => (album: a, count: await a.assetCountAsync)),
    );
    final nonEmpty = counted.where((r) => r.count > 0).toList()
      ..sort((a, b) {
        final diff =
            _albumPriority(a.album.name) - _albumPriority(b.album.name);
        return diff != 0 ? diff : a.album.name.compareTo(b.album.name);
      });
    if (!mounted) return;
    setState(() {
      _albums = nonEmpty.map((r) => r.album).toList();
      _recentlyDeleted = recentlyDeleted;
      _loading = false;
    });
  }

  Future<void> _showCreateAlbumDialog() async {
    // Return the trimmed name directly so the controller can be disposed
    // inside the dialog widget before we continue — avoids use-after-dispose
    // during the dialog's close animation.
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _CreateAlbumDialog(),
    );
    if (name == null || name.isEmpty) return;
    if (!Platform.isIOS && !Platform.isMacOS) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Album creation is only supported on iOS'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    try {
      await PhotoManager.editor.darwin.createAlbum(name);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create album: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAlbumDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Albums',
          style: AppTypography.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Special albums row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SpecialAlbumCard(
                            label: 'People',
                            icon: Icons.face_rounded,
                            isDark: isDark,
                            onTap: () => context.push(Routes.people),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SpecialAlbumCard(
                            label: 'Recently Deleted',
                            icon: Icons.delete_outline_rounded,
                            isDark: isDark,
                            onTap: _recentlyDeleted != null
                                ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _AlbumDetailPage(
                                            album: _recentlyDeleted!),
                                      ),
                                    )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_albums.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyAlbumsState(isDark: isDark),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final album = _albums[index];
                          return _AlbumCard(
                            album: album,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    _AlbumDetailPage(album: album),
                              ),
                            ),
                          );
                        },
                        childCount: _albums.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CreateAlbumDialog extends StatefulWidget {
  @override
  State<_CreateAlbumDialog> createState() => _CreateAlbumDialogState();
}

class _CreateAlbumDialogState extends State<_CreateAlbumDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'New Album',
        style: AppTypography.outfit(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Album name'),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _SpecialAlbumCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _SpecialAlbumCard({
    required this.label,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatefulWidget {
  final AssetPathEntity album;
  final bool isDark;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  Uint8List? _thumbnail;
  int _count = 0;
  bool _loadingThumb = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await widget.album.assetCountAsync;
    if (!mounted) return;
    setState(() => _count = count);
    if (count == 0) {
      setState(() => _loadingThumb = false);
      return;
    }
    final assets = await widget.album.getAssetListRange(start: 0, end: 1);
    if (assets.isEmpty || !mounted) return;
    final bytes = await assets.first.thumbnailDataWithSize(
      const ThumbnailSize(400, 400),
    );
    if (!mounted) return;
    setState(() {
      _thumbnail = bytes;
      _loadingThumb = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant,
                child: _loadingThumb
                    ? null
                    : _thumbnail != null
                        ? Image.memory(
                            _thumbnail!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : const Center(
                            child: Icon(
                              Icons.photo_outlined,
                              color: AppColors.muted,
                              size: 36,
                            ),
                          ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _albumTypeIcon(widget.album.name),
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  widget.album.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$_count',
            style: AppTypography.dmSans(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlbumsState extends StatelessWidget {
  final bool isDark;
  const _EmptyAlbumsState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.photo_album_outlined,
              size: 38,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No albums found',
            style: AppTypography.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Albums on your device will appear here',
            style: AppTypography.dmSans(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Private — album detail shown via Navigator.push
class _AlbumDetailPage extends StatefulWidget {
  final AssetPathEntity album;
  const _AlbumDetailPage({required this.album});

  @override
  State<_AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<_AlbumDetailPage> {
  List<MediaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await widget.album.assetCountAsync;
    if (count == 0) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final assets = await widget.album.getAssetListRange(
      start: 0,
      end: count,
    );
    final items = assets.map((a) => MediaItemModel.fromAsset(a)).toList();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.album.name,
              style: AppTypography.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (!_loading)
              Text(
                '${_items.length} items',
                style: AppTypography.dmSans(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        size: 48,
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No media in this album',
                        style: AppTypography.dmSans(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) => MediaThumbnail(
                    item: _items[index],
                    onTap: () => context.push(
                      Routes.viewer,
                      extra: ViewerArgs(
                        items: _items,
                        startIndex: index,
                      ),
                    ),
                  ),
                ),
    );
  }
}
