import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/face_detection_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../gallery/data/models/media_item_model.dart';
import '../../../gallery/domain/entities/media_item.dart';
import '../../../gallery/presentation/widgets/media_thumbnail.dart';
import '../../../viewer/presentation/pages/viewer_page.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

enum _ScanStatus { idle, scanning, done }

class _PeoplePageState extends State<PeoplePage> {
  _ScanStatus _status = _ScanStatus.idle;
  int _total = 0;
  int _processed = 0;
  bool _cancelled = false;

  final List<MediaItem> _solo = [];
  final List<MediaItem> _together = [];
  final List<MediaItem> _group = [];

  final _service = FaceDetectionService();

  @override
  void dispose() {
    _cancelled = true;
    _service.close();
    super.dispose();
  }

  void _cancelScan() {
    _cancelled = true;
    setState(() => _status = _ScanStatus.idle);
  }

  Future<void> _startScan() async {
    _cancelled = false;
    setState(() {
      _status = _ScanStatus.scanning;
      _processed = 0;
      _solo.clear();
      _together.clear();
      _group.clear();
    });

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (_cancelled || paths.isEmpty || !mounted) {
      if (mounted && !_cancelled) setState(() => _status = _ScanStatus.done);
      return;
    }

    final total = await paths.first.assetCountAsync;
    if (_cancelled || !mounted) return;
    setState(() => _total = total);

    const batchSize = 10;
    for (int start = 0; start < total; start += batchSize) {
      if (_cancelled || !mounted) return;
      final end = (start + batchSize).clamp(0, total);
      final assets = await paths.first.getAssetListRange(
          start: start, end: end);
      for (final asset in assets) {
        if (_cancelled || !mounted) return;
        final count = await _service.countFaces(asset);
        if (_cancelled || !mounted) return;
        final item = MediaItemModel.fromAsset(asset);
        if (count == 1) {
          _solo.add(item);
        } else if (count == 2) {
          _together.add(item);
        } else if (count >= 3) {
          _group.add(item);
        }
        setState(() => _processed++);
        // Yield so Flutter can repaint between each photo
        await Future.delayed(Duration.zero);
      }
    }

    if (!_cancelled && mounted) setState(() => _status = _ScanStatus.done);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'People',
          style: AppTypography.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_status == _ScanStatus.scanning)
            TextButton(
              onPressed: _cancelScan,
              child: Text(
                'Cancel',
                style: AppTypography.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          if (_status == _ScanStatus.done)
            TextButton(
              onPressed: _startScan,
              child: Text(
                'Rescan',
                style: AppTypography.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: switch (_status) {
        _ScanStatus.idle => _IdleBody(isDark: isDark, onScan: _startScan),
        _ScanStatus.scanning => _ScanningBody(
            processed: _processed,
            total: _total,
            isDark: isDark,
          ),
        _ScanStatus.done => _ResultsBody(
            solo: _solo,
            together: _together,
            group: _group,
            isDark: isDark,
          ),
      },
    );
  }
}


class _IdleBody extends StatelessWidget {
  final bool isDark;
  final VoidCallback onScan;
  const _IdleBody({required this.isDark, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.face_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Find People in Photos',
              style: AppTypography.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'SnapTune scans your library on-device to find photos with 1, 2, or more people. Nothing leaves your phone.',
              style: AppTypography.dmSans(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Person identity recognition coming in a future update.',
              style: AppTypography.dmSans(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(180),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Scan Library'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ScanningBody extends StatelessWidget {
  final int processed;
  final int total;
  final bool isDark;
  const _ScanningBody(
      {required this.processed, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? processed / total : 0.0;
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
                color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanning…',
              style: AppTypography.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$processed of $total photos',
              style: AppTypography.dmSans(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant,
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ResultsBody extends StatelessWidget {
  final List<MediaItem> solo;
  final List<MediaItem> together;
  final List<MediaItem> group;
  final bool isDark;

  const _ResultsBody({
    required this.solo,
    required this.together,
    required this.group,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = solo.length + together.length + group.length;

    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.face_retouching_off_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'No faces found',
                style: AppTypography.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No photos with faces were detected in your library.',
                style: AppTypography.dmSans(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Summary chip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Text(
              '$total photos with people detected',
              style: AppTypography.dmSans(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        if (solo.isNotEmpty) ..._section(context, 'Solo', Icons.person_rounded, solo),
        if (together.isNotEmpty) ..._section(context, 'Together', Icons.people_rounded, together),
        if (group.isNotEmpty) ..._section(context, 'Group', Icons.groups_rounded, group),
        SliverPadding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ),
      ],
    );
  }

  List<Widget> _section(
      BuildContext context, String title, IconData icon, List<MediaItem> items) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '$title  ·  ${items.length}',
                style: AppTypography.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => MediaThumbnail(
            item: items[i],
            onTap: () => context.push(
              Routes.viewer,
              extra: ViewerArgs(items: items, startIndex: i),
            ),
          ),
          childCount: items.length,
        ),
      ),
    ];
  }
}
