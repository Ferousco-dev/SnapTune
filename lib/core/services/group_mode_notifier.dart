import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GroupMode { day, month, year }

class GroupModeNotifier extends ValueNotifier<GroupMode> {
  static const _key = 'group_mode';

  final SharedPreferences _prefs;

  GroupModeNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(_fromString(prefs.getString(_key)));

  static GroupMode _fromString(String? s) => switch (s) {
        'day' => GroupMode.day,
        'year' => GroupMode.year,
        _ => GroupMode.month,
      };

  Future<void> setMode(GroupMode mode) async {
    if (value == mode) return;
    value = mode;
    await _prefs.setString(_key, mode.name);
  }
}
