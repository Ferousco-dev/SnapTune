import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/grid_columns_notifier.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../viewer/presentation/pages/viewer_page.dart';
import '../../../optimize/presentation/pages/optimize_page.dart'
    show ProcessingArgs;
import '../../../optimize/domain/entities/platform_preset.dart';
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

enum _GroupMode { day, month, year }

class _GalleryView extends StatefulWidget {
  const _GalleryView();

  @override
  State<_GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<_GalleryView> {
  final _scrollController = ScrollController();
  bool _sortNewest = true;
  _GroupMode _groupMode = _GroupMode.month;
  final Set<String> _selectedIds = {};
  final _shareButtonKey = GlobalKey();

  // Pinch-to-zoom grid
  int _pinchStartColumns = 3;
  bool _isPinching = false;

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    _pinchStartColumns = sl<GridColumnsNotifier>().value;
    _isPinching = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isPinching || details.pointerCount < 2) return;
    // Pinch in (scale < 1) = more columns; pinch out (scale > 1) = fewer
    final next = (_pinchStartColumns / details.scale).round().clamp(2, 5);
    if (next != sl<GridColumnsNotifier>().value) {
      HapticFeedback.selectionClick();
      sl<GridColumnsNotifier>().setColumns(next);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) => _isPinching = false;

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

  Future<void> _shareSelected(List<MediaItem> sorted) async {
    if (_selectedIds.isEmpty) return;
    final items =
        sorted.where((i) => _selectedIds.contains(i.id)).toList();

    final files = <XFile>[];
    for (final item in items) {
      final asset = await AssetEntity.fromId(item.id);
      final file = await asset?.file;
      if (file != null) files.add(XFile(file.path));
    }
    if (files.isEmpty || !mounted) return;

    final box = _shareButtonKey.currentContext?.findRenderObject()
        as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 600, 100, 50);

    await Share.shareXFiles(files, sharePositionOrigin: origin);
  }

  Future<void> _confirmDelete() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(count: count),
    );
    if (confirmed != true || !mounted) return;

    await PhotoManager.editor.deleteWithIds(_selectedIds.toList());
    if (!mounted) return;
    setState(() => _selectedIds.clear());
    context.read<GalleryBloc>().add(const GalleryRefreshed());
  }

  void _optimizeSelected(List<MediaItem> sorted) {
    if (_selectedIds.isEmpty) return;
    final items =
        sorted.where((i) => _selectedIds.contains(i.id)).toList();
    _clearSelection();

    if (items.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Optimizing first of ${items.length} selected items'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    context.push(
      Routes.processing,
      extra: ProcessingArgs(
        item: items.first,
        preset: PlatformPreset.all.first,
      ),
    );
  }

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

  Map<String, List<MediaItem>> _groupItems(List<MediaItem> items) {
    final result = <String, List<MediaItem>>{};
    for (final item in items) {
      final String key;
      switch (_groupMode) {
        case _GroupMode.day:
          key = DateFormat('EEEE, d MMMM yyyy').format(item.createDate);
        case _GroupMode.month:
          key = DateFormat('MMMM yyyy').format(item.createDate);
        case _GroupMode.year:
          key = DateFormat('yyyy').format(item.createDate);
      }
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }

  void _cycleGroupMode() {
    setState(() {
      _groupMode = switch (_groupMode) {
        _GroupMode.day => _GroupMode.month,
        _GroupMode.month => _GroupMode.year,
        _GroupMode.year => _GroupMode.day,
      };
    });
    HapticFeedback.selectionClick();
  }

  String get _groupModeLabel => switch (_groupMode) {
        _GroupMode.day => 'Day',
        _GroupMode.month => 'Month',
        _GroupMode.year => 'Year',
      };

  List<Widget> _buildSectionSlivers(
      List<MediaItem> sorted, int crossAxisCount) {
    final grouped = _groupItems(sorted);
    final slivers = <Widget>[];
    for (final entry in grouped.entries) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
          ),
          child: Text(
            entry.key,
            style: AppTypography.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ));
      slivers.add(SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final item = entry.value[i];
            return MediaThumbnail(
              item: item,
              isSelecting: _isSelecting,
              isSelected: _selectedIds.contains(item.id),
              onTap: () {
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
              onLongPress: () {
                if (!_isSelecting) _enterSelectMode(item.id);
              },
            );
          },
          childCount: entry.value.length,
        ),
      ));
    }
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ValueListenableBuilder<int>(
        valueListenable: sl<GridColumnsNotifier>(),
        builder: (context, crossAxisCount, _) {
          return BlocBuilder<GalleryBloc, GalleryState>(
            builder: (context, state) {
              final sorted = _sorted(state.items);
              return Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    onScaleEnd: _onScaleEnd,
                    child: CustomScrollView(
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
                        groupModeLabel: _groupModeLabel,
                        onCycleGroup: _cycleGroupMode,
                      ),
                      if (!_isSelecting)
                        _FilterBar(activeFilter: state.activeFilter),
                      if (state.status == GalleryStatus.permissionDenied)
                        const SliverFillRemaining(
                            child: _PermissionDeniedView())
                      else if (state.status == GalleryStatus.loading &&
                          state.items.isEmpty)
                        const SliverFillRemaining(child: _LoadingView())
                      else if (state.isEmpty)
                        const SliverFillRemaining(child: _EmptyView())
                      else ...[
                        ..._buildSectionSlivers(sorted, crossAxisCount),
                        if (state.hasMore && state.isLoaded)
                          const SliverToBoxAdapter(
                              child: _LoadMoreIndicator()),
                        if (_isSelecting)
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 80)),
                      ],
                    ],
                  ),        // CustomScrollView
                  ),        // GestureDetector

                  if (_isSelecting)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _SelectionBar(
                        count: _selectedIds.length,
                        shareButtonKey: _shareButtonKey,
                        onShare: () => _shareSelected(sorted),
                        onOptimize: () => _optimizeSelected(sorted),
                        onDelete: _confirmDelete,
                      ),
                    ),
                ],
              );
            },
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
  final String groupModeLabel;
  final VoidCallback onCycleGroup;

  const _AppBar({
    required this.isDark,
    required this.onSearch,
    required this.onMore,
    required this.sortNewest,
    required this.isSelecting,
    required this.selectedCount,
    required this.onCancelSelect,
    required this.onSelectAll,
    required this.groupModeLabel,
    required this.onCycleGroup,
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
              GestureDetector(
                onTap: onCycleGroup,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(isDark ? 50 : 25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      groupModeLabel,
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: sl<GridColumnsNotifier>().value,
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


// ── Selection bar ─────────────────────────────────────────────────────────────

class _SelectionBar extends StatelessWidget {
  final int count;
  final Key? shareButtonKey;
  final VoidCallback onShare;
  final VoidCallback onOptimize;
  final VoidCallback onDelete;

  const _SelectionBar({
    required this.count,
    required this.onShare,
    required this.onOptimize,
    required this.onDelete,
    this.shareButtonKey,
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
            actionKey: shareButtonKey,
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
  final Key? actionKey;
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.actionKey,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      key: actionKey,
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

// ── Delete confirmation dialog ────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final int count;
  const _DeleteConfirmDialog({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemLabel = count == 1 ? '1 item' : '$count items';

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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(isDark ? 35 : 20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_rounded,
                  color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete $itemLabel?',
              style: AppTypography.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              count == 1
                  ? 'This item will be permanently removed from your library. This cannot be undone.'
                  : 'These $count items will be permanently removed from your library. This cannot be undone.',
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
                            fontWeight: FontWeight.w600,
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
