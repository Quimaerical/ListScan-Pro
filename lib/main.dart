import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/shopping_lists/data/datasources/shopping_list_local_datasource.dart';
import 'features/shopping_lists/data/repositories/shopping_list_repository_impl.dart';
import 'features/shopping_lists/presentation/controllers/shopping_lists_controller.dart';
import 'features/shopping_lists/presentation/views/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize data layer dependencies
  final ShoppingListLocalDataSource localDataSource =
      ShoppingListLocalDataSource();
  final ShoppingListRepositoryImpl repository = ShoppingListRepositoryImpl(
    localDataSource: localDataSource,
  );
  final SqliteSettingsRepository settingsRepository =
      SqliteSettingsRepository();

  // Initialize reactive controller with persisted settings
  final ShoppingListsController controller = ShoppingListsController(
    repository: repository,
    settingsRepository: settingsRepository,
  );
  await controller.loadSettings();

  runApp(ListScanProApp(controller: controller));
}

/// Root Application Widget configured with Material 3, light/dark themes
/// and reactive theme switching via [ListenableBuilder].
class ListScanProApp extends StatelessWidget {
  final ShoppingListsController controller;

  const ListScanProApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        return MaterialApp(
          title: 'ListScan PRO',
          debugShowCheckedModeBanner: false,
          themeMode: controller.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: DashboardScreen(controller: controller),
        );
      },
    );
  }
}

/// Backward compatibility alias
typedef ShopLiistProApp = ListScanProApp;
