import 'package:shared_preferences/shared_preferences.dart';

/// User preferences stored in SharedPreferences.
class SettingsRepository {
  const SettingsRepository(this._prefs);

  static const _ownerNamesKey = 'owner_names';
  static const _localeKey = 'locale';
  static const _lastLibraryScanKey = 'last_library_scan_ms';
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

  /// When the photo library was last fully searched for slips, if ever.
  DateTime? lastLibraryScan() {
    final ms = _prefs.getInt(_lastLibraryScanKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLastLibraryScan(DateTime time) => _prefs.setInt(_lastLibraryScanKey, time.millisecondsSinceEpoch);
}
