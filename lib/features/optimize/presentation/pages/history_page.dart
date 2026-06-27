import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/services/history_service.dart';
import '../../domain/entities/optimization_record.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<OptimizationRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await HistoryService.instance.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _delete(OptimizationRecord r) async {
    await HistoryService.instance.delete(r.id);
    if (!mounted) return;
    setState(() => _records.removeWhere((x) => x.id == r.id));
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes all optimization records.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await HistoryService.instance.clear();
    setState(() => _records = []);
  }

  String _fmtBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  String _fmtDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.background,
        title: Text(
          'History',
          style: AppTypography.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
        actions: [
          if (_records.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear all',
                style: AppTypography.dmSans(
                  fontSize: 13,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _EmptyState(isDark: isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _records.length,
                  itemBuilder: (_, i) => _HistoryTile(
                    record: _records[i],
                    isDark: isDark,
                    fmtBytes: _fmtBytes,
                    fmtDate: _fmtDate,
                    onDelete: () => _delete(_records[i]),
                    onShare: () async {
                      final path = _records[i].savedOutputPath;
                      if (path != null && File(path).existsSync()) {
                        await Share.shareXFiles([XFile(path)]);
                      }
                    },
                  ),
                ),
    );
  }
}


class _HistoryTile extends StatelessWidget {
  final OptimizationRecord record;
  final bool isDark;
  final String Function(int) fmtBytes;
  final String Function(int) fmtDate;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _HistoryTile({
    required this.record,
    required this.isDark,
    required this.fmtBytes,
    required this.fmtDate,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final hasSavings = record.savingsBytes > 0;
    final canShare = record.savedOutputPath != null &&
        File(record.savedOutputPath!).existsSync();

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (record.isVideo
                        ? const Color(0xFF7B61FF)
                        : AppColors.primary)
                    .withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                record.isVideo
                    ? Icons.videocam_rounded
                    : Icons.image_rounded,
                size: 20,
                color: record.isVideo
                    ? const Color(0xFF7B61FF)
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.filename.isEmpty ? 'Media file' : record.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        record.presetName,
                        style: AppTypography.dmSans(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' · ${fmtBytes(record.originalSizeBytes)} → '
                        '${fmtBytes(record.outputSizeBytes)}',
                        style: AppTypography.dmSans(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmtDate(record.timestampMs),
                    style: AppTypography.dmSans(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasSavings)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${record.savingsPct.toStringAsFixed(0)}%',
                      style: AppTypography.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF34C759),
                      ),
                    ),
                  ),
                if (canShare) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onShare,
                    child: Icon(
                      Icons.ios_share_rounded,
                      size: 18,
                      color:
                          isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 56,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
          const SizedBox(height: 16),
          Text(
            'No optimizations yet',
            style: AppTypography.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Files you optimize will appear here.',
            style: AppTypography.dmSans(
              fontSize: 13,
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
