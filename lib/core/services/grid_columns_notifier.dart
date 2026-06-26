import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GridColumnsNotifier extends ValueNotifier<int> {
  static const _key = 'grid_columns';
  static const _default = 3;

  final SharedPreferences _prefs;

  GridColumnsNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(prefs.getInt(_key) ?? _default);

  Future<void> setColumns(int count) async {
    if (value == count) return;
    value = count;
    await _prefs.setInt(_key, count);
  }
}
