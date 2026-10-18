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

  // Recipe APIs and Extraction preferences
  static const String customRecipeApiKey = 'custom_recipe_api_key';
  static const String customRecipeApiEndpoint = 'custom_recipe_api_endpoint';
  static const String geminiApiKey = 'gemini_api_key';
  static const String enableAsianRecipes = 'enable_asian_recipes';
  static const String enableTheMealDb = 'enable_themealdb';
  static const String recipeLanguage = 'recipe_language';
}
