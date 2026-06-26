import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _sortNewest = true;
  final Set<String> _selectedIds = {};

  bool get _isSelecting => _selectedIds.isNotEmpty;

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

  List<MediaItem> _sorted(List<MediaItem> items) {
    final copy = List<MediaItem>.from(items);
    copy.sort((a, b) => _sortNewest
        ? b.createDate.compareTo(a.createDate)
        : a.createDate.compareTo(b.createDate));
    return copy;
  }

  void _enterSelectMode(String id) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedIds.add(id));
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
        HapticFeedback.lightImpact();
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  void _selectAll(List<MediaItem> items) {
    HapticFeedback.lightImpact();
    setState(() => _selectedIds.addAll(items.map((i) => i.id)));
  }

  void _showMoreMenu(BuildContext ctx, List<MediaItem> items) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _GalleryOptionsSheet(
        isDark: isDark,
        sortNewest: _sortNewest,
        onSortNewest: () {
          Navigator.pop(sheetCtx);
          setState(() => _sortNewest = true);
        },
        onSortOldest: () {
          Navigator.pop(sheetCtx);
          setState(() => _sortNewest = false);
        },
        onRefresh: () {
          Navigator.pop(sheetCtx);
          ctx.read<GalleryBloc>().add(const GalleryRefreshed());
        },
      ),
    );
  }

  void _openSearch(List<MediaItem> items) {
    showSearch<MediaItem?>(
      context: context,
      delegate: _GallerySearchDelegate(items: items),
    ).then((result) {
      if (result != null && mounted) {
        context.push(
          Routes.viewer,
          extra: ViewerArgs(items: items, startIndex: items.indexOf(result)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<GalleryBloc, GalleryState>(
        builder: (context, state) {
          final sorted = _sorted(state.items);
          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _AppBar(
                    isDark: isDark,
                    onSearch: () => _openSearch(state.items),
                    onMore: () => _showMoreMenu(context, state.items),
                    sortNewest: _sortNewest,
                    isSelecting: _isSelecting,
                    selectedCount: _selectedIds.length,
                    onCancelSelect: _clearSelection,
                    onSelectAll: () => _selectAll(sorted),
                  ),
                  if (!_isSelecting)
                    _FilterBar(activeFilter: state.activeFilter),
                  if (state.status == GalleryStatus.permissionDenied)
                    const SliverFillRemaining(child: _PermissionDeniedView())
                  else if (state.status == GalleryStatus.loading &&
                      state.items.isEmpty)
                    const SliverFillRemaining(child: _LoadingView())
                  else if (state.isEmpty)
                    const SliverFillRemaining(child: _EmptyView())
                  else ...[
                    _MediaGrid(
                      items: sorted,
                      selectedIds: _selectedIds,
                      isSelecting: _isSelecting,
                      onTap: (item) {
                        if (_isSelecting) {
                          _toggleSelect(item.id);
                        } else {
                          context.push(
                            Routes.viewer,
                            extra: ViewerArgs(
                              items: sorted,
                              startIndex: sorted.indexOf(item),
                            ),
                          );
                        }
                      },
                      onLongPress: (item) {
                        if (!_isSelecting) _enterSelectMode(item.id);
                      },
                    ),
                    if (state.hasMore && state.isLoaded)
                      const SliverToBoxAdapter(
                          child: _LoadMoreIndicator()),
                    // Bottom padding so selection bar doesn't hide last row
                    if (_isSelecting)
                      const SliverToBoxAdapter(
                          child: SizedBox(height: 80)),
                  ],
                ],
              ),

              // Selection action bar
              if (_isSelecting)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _SelectionBar(
                    count: _selectedIds.length,
                    onShare: () {},
                    onOptimize: () {},
                    onDelete: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delete coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final bool isDark;
  final bool sortNewest;
  final VoidCallback onSearch;
  final VoidCallback onMore;
  final bool isSelecting;
  final int selectedCount;
  final VoidCallback onCancelSelect;
  final VoidCallback onSelectAll;

  const _AppBar({
    required this.isDark,
    required this.onSearch,
    required this.onMore,
    required this.sortNewest,
    required this.isSelecting,
    required this.selectedCount,
    required this.onCancelSelect,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: isSelecting
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: onCancelSelect,
            )
          : null,
      automaticallyImplyLeading: false,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSelecting
            ? Text(
                '$selectedCount selected',
                key: const ValueKey('select'),
                style: AppTypography.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              )
            : Text(
                'Gallery',
                key: const ValueKey('gallery'),
                style: AppTypography.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
      ),
      actions: isSelecting
          ? [
              TextButton(
                onPressed: onSelectAll,
                child: Text(
                  'Select All',
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ]
          : [
              IconButton(
                icon: Icon(Icons.search_rounded,
                    color: Theme.of(context).colorScheme.onSurface),
                onPressed: onSearch,
              ),
              IconButton(
                icon: Icon(Icons.more_vert_rounded,
                    color: Theme.of(context).colorScheme.onSurface),
                onPressed: onMore,
              ),
              const SizedBox(width: 4),
            ],
    );
  }
}

// ── Gallery options sheet ─────────────────────────────────────────────────────

class _GalleryOptionsSheet extends StatelessWidget {
  final bool isDark;
  final bool sortNewest;
  final VoidCallback onSortNewest;
  final VoidCallback onSortOldest;
  final VoidCallback onRefresh;

  const _GalleryOptionsSheet({
    required this.isDark,
    required this.sortNewest,
    required this.onSortNewest,
    required this.onSortOldest,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
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
              color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),

          // Sort section header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 14, AppSpacing.md, 6),
            child: Row(
              children: [
                Text(
                  'Sort by',
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          _OptionTile(
            icon: Icons.arrow_downward_rounded,
            label: 'Newest first',
            isDark: isDark,
            trailing: sortNewest
                ? const Icon(Icons.check_rounded,
                    color: AppColors.primary, size: 18)
                : null,
            onTap: onSortNewest,
          ),
          _OptionTile(
            icon: Icons.arrow_upward_rounded,
            label: 'Oldest first',
            isDark: isDark,
            trailing: !sortNewest
                ? const Icon(Icons.check_rounded,
                    color: AppColors.primary, size: 18)
                : null,
            onTap: onSortOldest,
          ),

          _SheetDivider(isDark: isDark),

          _OptionTile(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            isDark: isDark,
            onTap: onRefresh,
          ),
          _OptionTile(
            icon: Icons.check_box_outline_blank_rounded,
            label: 'Select items',
            isDark: isDark,
            onTap: () => Navigator.pop(context),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTypography.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  final bool isDark;
  const _SheetDivider({required this.isDark});

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

// ── Search delegate ───────────────────────────────────────────────────────────

class _GallerySearchDelegate extends SearchDelegate<MediaItem?> {
  final List<MediaItem> items;

  _GallerySearchDelegate({required this.items});

  @override
  String get searchFieldLabel => 'Search by date or month...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  List<MediaItem> get _filtered {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return items.where((item) {
      final label = DateFormat('MMMM yyyy').format(item.createDate).toLowerCase();
      final dayLabel = DateFormat('d MMMM yyyy').format(item.createDate).toLowerCase();
      return label.contains(q) || dayLabel.contains(q);
    }).toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return _RecentMonths(
        items: items,
        onTap: (month) => query = month,
      );
    }
    return _ResultGrid(
      results: _filtered,
      allItems: items,
      onTap: (item) => close(context, item),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filtered;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No results for "$query"',
              style: AppTypography.dmSans(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return _ResultGrid(
      results: results,
      allItems: items,
      onTap: (item) => close(context, item),
    );
  }
}

class _RecentMonths extends StatelessWidget {
  final List<MediaItem> items;
  final void Function(String) onTap;

  const _RecentMonths({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final months = <String>{};
    for (final item in items) {
      months.add(DateFormat('MMMM yyyy').format(item.createDate));
    }
    final sorted = months.toList()..sort((a, b) => b.compareTo(a));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Recent months',
          style: AppTypography.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sorted.take(12).map((month) {
            return GestureDetector(
              onTap: () => onTap(month),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  month,
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ResultGrid extends StatelessWidget {
  final List<MediaItem> results;
  final List<MediaItem> allItems;
  final void Function(MediaItem) onTap;

  const _ResultGrid({
    required this.results,
    required this.allItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) => MediaThumbnail(
        item: results[i],
        onTap: () => onTap(results[i]),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.key,
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.onSurfaceVariant),
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

// ── Media grid ────────────────────────────────────────────────────────────────

class _MediaGrid extends StatelessWidget {
  final List<MediaItem> items;
  final Set<String> selectedIds;
  final bool isSelecting;
  final void Function(MediaItem) onTap;
  final void Function(MediaItem) onLongPress;

  const _MediaGrid({
    required this.items,
    required this.selectedIds,
    required this.isSelecting,
    required this.onTap,
    required this.onLongPress,
  });

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
            selectedIds: selectedIds,
            isSelecting: isSelecting,
            onTap: onTap,
            onLongPress: onLongPress,
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
  final Set<String> selectedIds;
  final bool isSelecting;
  final void Function(MediaItem) onTap;
  final void Function(MediaItem) onLongPress;

  const _MonthSection({
    required this.label,
    required this.sectionItems,
    required this.selectedIds,
    required this.isSelecting,
    required this.onTap,
    required this.onLongPress,
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
            return MediaThumbnail(
              item: item,
              isSelecting: isSelecting,
              isSelected: selectedIds.contains(item.id),
              onTap: () => onTap(item),
              onLongPress: () => onLongPress(item),
            );
          },
        ),
      ],
    );
  }
}

// ── Selection bar ─────────────────────────────────────────────────────────────

class _SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onShare;
  final VoidCallback onOptimize;
  final VoidCallback onDelete;

  const _SelectionBar({
    required this.count,
    required this.onShare,
    required this.onOptimize,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 20),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 8,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SelectionAction(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: onShare,
          ),
          _SelectionAction(
            icon: Icons.auto_fix_high_rounded,
            label: 'Optimize',
            color: AppColors.primary,
            onTap: onOptimize,
          ),
          _SelectionAction(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: AppColors.error,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SelectionAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── State views ───────────────────────────────────────────────────────────────

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
              onPressed: () =>
                  context.read<GalleryBloc>().add(const GalleryStarted()),
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
