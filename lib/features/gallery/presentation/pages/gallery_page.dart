import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../viewer/presentation/pages/viewer_page.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/media_item.dart';
import '../bloc/gallery_bloc.dart';
import '../bloc/gallery_event.dart';
import '../bloc/gallery_state.dart';
import '../widgets/media_thumbnail.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GalleryBloc>()..add(const GalleryStarted()),
      child: const _GalleryView(),
    );
  }
}

class _GalleryView extends StatefulWidget {
  const _GalleryView();

  @override
  State<_GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<_GalleryView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      context.read<GalleryBloc>().add(const GalleryLoadMore());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<GalleryBloc, GalleryState>(
        builder: (context, state) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _AppBar(isDark: isDark),
              _FilterBar(activeFilter: state.activeFilter),
              if (state.status == GalleryStatus.permissionDenied)
                const SliverFillRemaining(child: _PermissionDeniedView())
              else if (state.status == GalleryStatus.loading && state.items.isEmpty)
                const SliverFillRemaining(child: _LoadingView())
              else if (state.isEmpty)
                const SliverFillRemaining(child: _EmptyView())
              else ...[
                _MediaGrid(items: state.items),
                if (state.hasMore && state.isLoaded)
                  const SliverToBoxAdapter(child: _LoadMoreIndicator()),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final bool isDark;
  const _AppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text(
        'Gallery',
        style: AppTypography.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final MediaType? activeFilter;
  const _FilterBar({required this.activeFilter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = <String, MediaType?>{
      'All': null,
      'Photos': MediaType.image,
      'Videos': MediaType.video,
    };

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final entry = filters.entries.elementAt(i);
            final isActive = activeFilter == entry.value;
            return GestureDetector(
              onTap: () => context
                  .read<GalleryBloc>()
                  .add(GalleryFilterChanged(entry.value)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.key,
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<MediaItem> items;
  const _MediaGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByMonth(items);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, sectionIndex) {
          final entry = grouped.entries.elementAt(sectionIndex);
          return _MonthSection(
            label: entry.key,
            sectionItems: entry.value,
            allItems: items,
          );
        },
        childCount: grouped.length,
      ),
    );
  }

  Map<String, List<MediaItem>> _groupByMonth(List<MediaItem> items) {
    final result = <String, List<MediaItem>>{};
    for (final item in items) {
      final key = DateFormat('MMMM yyyy').format(item.createDate);
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }
}

class _MonthSection extends StatelessWidget {
  final String label;
  final List<MediaItem> sectionItems;
  final List<MediaItem> allItems;

  const _MonthSection({
    required this.label,
    required this.sectionItems,
    required this.allItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: sectionItems.length,
          itemBuilder: (_, i) {
            final item = sectionItems[i];
            final globalIndex = allItems.indexOf(item);
            return MediaThumbnail(
              item: item,
              onTap: () => context.push(
                Routes.viewer,
                extra: ViewerArgs(items: allItems, startIndex: globalIndex),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Photo Access Required',
              style: AppTypography.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Allow SnapTune to access your photos so you can browse and optimize your media.',
              style: AppTypography.dmSans(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => context
                  .read<GalleryBloc>()
                  .add(const GalleryStarted()),
              child: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 24,
      itemBuilder: (_, _) => _ShimmerCell(),
    );
  }
}

class _ShimmerCell extends StatefulWidget {
  @override
  State<_ShimmerCell> createState() => _ShimmerCellState();
}

class _ShimmerCellState extends State<_ShimmerCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        color: Color.lerp(
          isDark ? AppColors.darkSurface : AppColors.surfaceVariant,
          isDark ? AppColors.darkSurfaceVariant : AppColors.outlineVariant,
          _ctrl.value,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No media found',
        style: AppTypography.dmSans(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
