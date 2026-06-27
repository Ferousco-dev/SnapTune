import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/optimization_record.dart';

class HistoryService {
  static const _key = 'snaptune_history_v1';
  static const _maxRecords = 200;

  static HistoryService? _instance;
  HistoryService._();
  static HistoryService get instance => _instance ??= HistoryService._();

  Future<List<OptimizationRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final records = <OptimizationRecord>[];
    for (final s in raw) {
      try {
        records.add(OptimizationRecord.fromJson(
            json.decode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    // Newest first
    records.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    return records;
  }

  Future<void> save(OptimizationRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = List<String>.from(prefs.getStringList(_key) ?? []);
    raw.insert(0, json.encode(record.toJson()));
    if (raw.length > _maxRecords) raw.removeRange(_maxRecords, raw.length);
    await prefs.setStringList(_key, raw);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = List<String>.from(prefs.getStringList(_key) ?? []);
    raw.removeWhere((s) {
      try {
        return (json.decode(s) as Map<String, dynamic>)['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ── Aggregate helpers ─────────────────────────────────────────────────────

  // Daily savings in bytes for the last [days] days, index 0 = oldest.
  static List<int> dailySavings(List<OptimizationRecord> records, int days) {
    final now = DateTime.now();
    final buckets = List<int>.filled(days, 0);
    for (final r in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.timestampMs);
      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < days) {
        buckets[days - 1 - diff] += r.savingsBytes;
      }
    }
    return buckets;
  }

  static int totalSavingsBytes(List<OptimizationRecord> records) =>
      records.fold(0, (s, r) => s + r.savingsBytes);

  // Best preset by average savings percent (min 3 records to qualify)
  static String? bestPresetName(List<OptimizationRecord> records) {
    final groups = <String, List<double>>{};
    for (final r in records) {
      groups.putIfAbsent(r.presetName, () => []).add(r.savingsPct);
    }
    String? best;
    double bestAvg = 0;
    groups.forEach((name, pcts) {
      if (pcts.length < 3) return;
      final avg = pcts.reduce((a, b) => a + b) / pcts.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        best = name;
      }
    });
    return best;
  }
}
