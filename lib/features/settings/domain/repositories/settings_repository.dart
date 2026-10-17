/// Abstract contract for persisting user preferences (theme, view mode, ...).
///
/// Values are stored as plain strings in a key/value table so new settings
/// can be added without schema migrations.
abstract class SettingsRepository {
  /// Loads every persisted preference at once (single query at startup).
  Future<Map<String, String>> loadAll();

  /// Inserts or replaces a single preference.
  Future<void> setValue(String key, String value);
}

/// Well-known preference keys, centralised to avoid typos.
abstract final class SettingsKeys {
  static const String themeMode = 'theme_mode';
  static const String isGridView = 'is_grid_view';
  static const String completedExpanded = 'completed_expanded';
}
