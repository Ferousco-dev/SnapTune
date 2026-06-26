import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/liked_ids_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../gallery/data/models/media_item_model.dart';
import '../../../gallery/domain/entities/media_item.dart';
import '../../../gallery/presentation/widgets/media_thumbnail.dart';
import '../../../viewer/presentation/pages/viewer_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<MediaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    sl<LikedIdsNotifier>().addListener(_onLikesChanged);
    _load();
  }

  @override
  void dispose() {
    sl<LikedIdsNotifier>().removeListener(_onLikesChanged);
    super.dispose();
  }

  void _onLikesChanged() => _load();

  Future<void> _load() async {
    final ids = sl<LikedIdsNotifier>().likedIds;
    if (ids.isEmpty) {
      if (mounted) setState(() { _items = []; _loading = false; });
      return;
    }

    final items = <MediaItem>[];
    for (final id in ids) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) items.add(MediaItemModel.fromAsset(asset));
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
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
          'Favorites',
          style: AppTypography.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (!_loading && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  '${_items.length}',
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _EmptyFavoritesState(isDark: isDark)
              : GridView.builder(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom +
                        AppSpacing.md,
                  ),
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

class _EmptyFavoritesState extends StatelessWidget {
  final bool isDark;
  const _EmptyFavoritesState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No favorites yet',
              style: AppTypography.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart in the viewer to save photos here.',
              textAlign: TextAlign.center,
              style: AppTypography.dmSans(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
