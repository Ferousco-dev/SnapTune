import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikedIdsNotifier extends ChangeNotifier {
  static const _key = 'liked_ids';

  final SharedPreferences _prefs;
  final Set<String> _ids;

  LikedIdsNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        _ids = _load(prefs);

  static Set<String> _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(_key);
    return raw != null ? Set<String>.from(raw) : {};
  }

  bool isLiked(String id) => _ids.contains(id);

  Set<String> get likedIds => Set.unmodifiable(_ids);

  Future<void> toggle(String id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    await _prefs.setStringList(_key, _ids.toList());
  }
}
