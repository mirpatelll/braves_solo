import 'package:shared_preferences/shared_preferences.dart';

/// How the roster list is ordered. Persisted as a string in shared_preferences.
enum SortOrder { nameAsc, nameDesc, jersey }

/// Lightweight key/value settings that should survive restarts but don't
/// belong in SQLite: theme choice, list sort order, and the last search query.
class PrefsService {
  static const _kDarkMode = 'darkMode';
  static const _kSortOrder = 'sortOrder';
  static const _kLastQuery = 'lastQuery';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  // --- Dark mode ---------------------------------------------------------
  Future<bool> getDarkMode() async {
    final prefs = await _instance;
    return prefs.getBool(_kDarkMode) ?? false; // sensible default
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_kDarkMode, value);
  }

  // --- Sort order --------------------------------------------------------
  Future<SortOrder> getSortOrder() async {
    final prefs = await _instance;
    final name = prefs.getString(_kSortOrder);
    return SortOrder.values.firstWhere(
      (o) => o.name == name,
      orElse: () => SortOrder.nameAsc,
    );
  }

  Future<void> setSortOrder(SortOrder order) async {
    final prefs = await _instance;
    await prefs.setString(_kSortOrder, order.name);
  }

  // --- Last search query -------------------------------------------------
  Future<String> getLastQuery() async {
    final prefs = await _instance;
    return prefs.getString(_kLastQuery) ?? '';
  }

  Future<void> setLastQuery(String query) async {
    final prefs = await _instance;
    await prefs.setString(_kLastQuery, query);
  }
}
