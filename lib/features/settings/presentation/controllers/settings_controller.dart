import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../shopping_lists/data/datasources/sqlite_db_helper.dart';
import '../../../shopping_lists/presentation/controllers/shopping_lists_controller.dart';
import '../../domain/repositories/settings_repository.dart';

/// Controller managing persistent settings, API configurations, and database stats.
class SettingsController extends ChangeNotifier {
  final SettingsRepository settingsRepository;
  final ShoppingListsController? shoppingListsController;
  final SqliteDbHelper _dbHelper;

  SettingsController({
    required this.settingsRepository,
    this.shoppingListsController,
    SqliteDbHelper? dbHelper,
  }) : _dbHelper = dbHelper ?? SqliteDbHelper.instance;

  bool _isLoading = false;
  bool _enableAsianRecipes = true;
  bool _enableTheMealDb = true;
  String _customRecipeApiKey = '';
  String _customRecipeApiEndpoint = '';
  String _geminiApiKey = '';
  String _recipeLanguage = 'es';
  int _databaseListCount = 0;
  int _databaseItemCount = 0;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isGridView = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get enableAsianRecipes => _enableAsianRecipes;
  bool get enableTheMealDb => _enableTheMealDb;
  String get customRecipeApiKey => _customRecipeApiKey;
  String get customRecipeApiEndpoint => _customRecipeApiEndpoint;
  String get geminiApiKey => _geminiApiKey;
  String get recipeLanguage => _recipeLanguage;
  int get databaseListCount => _databaseListCount;
  int get databaseItemCount => _databaseItemCount;

  ThemeMode get themeMode => shoppingListsController?.themeMode ?? _themeMode;
  bool get isGridView => shoppingListsController?.isGridView ?? _isGridView;

  /// Loads all settings and queries database statistics.
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, String> settings = await settingsRepository.loadAll();

      final String? asianSetting = settings[SettingsKeys.enableAsianRecipes];
      _enableAsianRecipes = asianSetting != '0' && asianSetting != 'false';

      final String? mealDbSetting = settings[SettingsKeys.enableTheMealDb];
      _enableTheMealDb = mealDbSetting != '0' && mealDbSetting != 'false';

      _customRecipeApiKey = settings[SettingsKeys.customRecipeApiKey] ?? '';
      _customRecipeApiEndpoint =
          settings[SettingsKeys.customRecipeApiEndpoint] ?? '';
      _geminiApiKey = settings[SettingsKeys.geminiApiKey] ?? '';
      _recipeLanguage = settings[SettingsKeys.recipeLanguage] ?? 'es';

      final String? themeVal = settings[SettingsKeys.themeMode];
      if (themeVal == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (themeVal == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeVal == 'system') {
        _themeMode = ThemeMode.system;
      }

      final String? gridSetting = settings[SettingsKeys.isGridView];
      _isGridView = gridSetting == '1' || gridSetting == 'true';

      await _refreshDatabaseStats();
    } catch (_) {
      // Graceful fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshDatabaseStats() async {
    try {
      final Database db = await _dbHelper.database;
      final List<Map<String, Object?>> listsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${SqliteDbHelper.tableLists}',
      );
      final List<Map<String, Object?>> itemsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${SqliteDbHelper.tableItems}',
      );

      _databaseListCount = (listsResult.first['count'] as num?)?.toInt() ?? 0;
      _databaseItemCount = (itemsResult.first['count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // In-memory or test fallback
      _databaseListCount = shoppingListsController?.lists.length ?? 0;
      _databaseItemCount =
          shoppingListsController?.lists.fold<int>(
            0,
            (acc, l) => acc + l.items.length,
          ) ??
          0;
    }
  }

  Future<void> setEnableAsianRecipes(bool value) async {
    _enableAsianRecipes = value;
    notifyListeners();
    await settingsRepository.setValue(
      SettingsKeys.enableAsianRecipes,
      value ? '1' : '0',
    );
  }

  Future<void> setEnableTheMealDb(bool value) async {
    _enableTheMealDb = value;
    notifyListeners();
    await settingsRepository.setValue(
      SettingsKeys.enableTheMealDb,
      value ? '1' : '0',
    );
  }

  Future<void> setCustomRecipeApiKey(String key) async {
    _customRecipeApiKey = key.trim();
    notifyListeners();
    await settingsRepository.setValue(
      SettingsKeys.customRecipeApiKey,
      _customRecipeApiKey,
    );
  }

  Future<void> setCustomRecipeApiEndpoint(String endpoint) async {
    _customRecipeApiEndpoint = endpoint.trim();
    notifyListeners();
    await settingsRepository.setValue(
      SettingsKeys.customRecipeApiEndpoint,
      _customRecipeApiEndpoint,
    );
  }

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key.trim();
    notifyListeners();
    await settingsRepository.setValue(SettingsKeys.geminiApiKey, _geminiApiKey);
  }

  Future<void> setRecipeLanguage(String language) async {
    _recipeLanguage = language;
    notifyListeners();
    await settingsRepository.setValue(
      SettingsKeys.recipeLanguage,
      _recipeLanguage,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    if (shoppingListsController != null &&
        shoppingListsController!.themeMode != mode) {
      shoppingListsController!.toggleThemeMode();
    } else {
      final String val = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.light ? 'light' : 'system');
      await settingsRepository.setValue(SettingsKeys.themeMode, val);
    }
  }

  Future<void> toggleGridView() async {
    if (shoppingListsController != null) {
      shoppingListsController!.toggleViewMode();
      _isGridView = shoppingListsController!.isGridView;
    } else {
      _isGridView = !_isGridView;
      await settingsRepository.setValue(
        SettingsKeys.isGridView,
        _isGridView ? 'true' : 'false',
      );
    }
    notifyListeners();
  }

  Future<void> refreshDatabaseStats() async {
    await _refreshDatabaseStats();
    notifyListeners();
  }
}
