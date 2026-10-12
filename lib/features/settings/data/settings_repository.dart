import 'package:shared_preferences/shared_preferences.dart';

/// User preferences stored in SharedPreferences.
class SettingsRepository {
  const SettingsRepository(this._prefs);

  static const _ownerNamesKey = 'owner_names';
  static const _localeKey = 'locale';
  static const defaultLocale = 'th';
  static const supportedLocales = ['th', 'en'];

  final SharedPreferences _prefs;

  List<String> ownerNames() => List.unmodifiable(_prefs.getStringList(_ownerNamesKey) ?? const []);

  Future<void> saveOwnerNames(List<String> names) => _prefs.setStringList(_ownerNamesKey, names);

  String localeCode() {
    final stored = _prefs.getString(_localeKey);
    return supportedLocales.contains(stored) ? stored! : defaultLocale;
  }

  Future<void> saveLocaleCode(String code) {
    if (!supportedLocales.contains(code)) {
      throw ArgumentError.value(code, 'code', 'Unsupported locale');
    }
    return _prefs.setString(_localeKey, code);
  }
}
