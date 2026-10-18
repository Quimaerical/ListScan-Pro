import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/features/settings/domain/repositories/settings_repository.dart';
import 'package:shopliist_pro/features/settings/presentation/controllers/settings_controller.dart';

class InMemorySettingsRepository implements SettingsRepository {
  final Map<String, String> store = <String, String>{};

  @override
  Future<Map<String, String>> loadAll() async =>
      Map<String, String>.from(store);

  @override
  Future<void> setValue(String key, String value) async {
    store[key] = value;
  }
}

void main() {
  group('SettingsController', () {
    late InMemorySettingsRepository repo;
    late SettingsController controller;

    setUp(() {
      repo = InMemorySettingsRepository();
      controller = SettingsController(settingsRepository: repo);
    });

    test('initial state has default configuration', () {
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isGridView, false);
      expect(controller.enableTheMealDb, true);
      expect(controller.enableAsianRecipes, true);
      expect(controller.customRecipeApiKey, isEmpty);
      expect(controller.geminiApiKey, isEmpty);
    });

    test('loadSettings loads saved preferences correctly', () async {
      repo.store[SettingsKeys.themeMode] = 'dark';
      repo.store[SettingsKeys.isGridView] = '1';
      repo.store[SettingsKeys.enableAsianRecipes] = '0';
      repo.store[SettingsKeys.customRecipeApiKey] = 'my_secret_key';

      await controller.loadSettings();

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isGridView, true);
      expect(controller.enableAsianRecipes, false);
      expect(controller.customRecipeApiKey, 'my_secret_key');
    });

    test('setThemeMode updates state and persists to repository', () async {
      await controller.setThemeMode(ThemeMode.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(repo.store[SettingsKeys.themeMode], 'dark');
    });

    test('toggleGridView toggles state and persists', () async {
      await controller.toggleGridView();

      expect(controller.isGridView, true);
      expect(repo.store[SettingsKeys.isGridView], 'true');
    });

    test('recipe providers and API keys persist properly', () async {
      await controller.setEnableAsianRecipes(false);
      expect(controller.enableAsianRecipes, false);
      expect(repo.store[SettingsKeys.enableAsianRecipes], '0');

      await controller.setEnableTheMealDb(false);
      expect(controller.enableTheMealDb, false);
      expect(repo.store[SettingsKeys.enableTheMealDb], '0');

      await controller.setCustomRecipeApiKey('api_123');
      expect(controller.customRecipeApiKey, 'api_123');
      expect(repo.store[SettingsKeys.customRecipeApiKey], 'api_123');

      await controller.setGeminiApiKey('gemini_xyz');
      expect(controller.geminiApiKey, 'gemini_xyz');
      expect(repo.store[SettingsKeys.geminiApiKey], 'gemini_xyz');
    });
  });
}
