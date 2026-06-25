import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _keyOnboardingDone = 'onboarding_done';

  final SharedPreferences _prefs;
  PrefsService(this._prefs);

  bool get isOnboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingDone() =>
      _prefs.setBool(_keyOnboardingDone, true);
}
