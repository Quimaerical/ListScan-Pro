import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/theme/app_colors.dart';
import 'package:shopliist_pro/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:shopliist_pro/features/settings/domain/repositories/settings_repository.dart';
import 'package:shopliist_pro/features/shopping_lists/data/services/list_file_handler.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_item.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_list.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/controllers/shopping_lists_controller.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/list_separator_tile.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/shopping_item_tile.dart';

class _FakeShoppingListRepository implements ShoppingListRepository {
  final List<ShoppingList> _lists = <ShoppingList>[];

  @override
  Future<List<ShoppingList>> getAllLists({bool includeArchived = false}) async => _lists;

  @override
  Future<ShoppingList?> getListById(String id) async =>
      _lists.cast<ShoppingList?>().firstWhere((ShoppingList? l) => l?.id == id, orElse: () => null);

  @override
  Future<void> saveList(ShoppingList list) async {
    _lists.add(list);
  }

  @override
  Future<void> deleteList(String id) async {
    _lists.removeWhere((ShoppingList l) => l.id == id);
  }

  @override
  Future<void> togglePinList(String id) async {}

  @override
  Future<void> setArchived(String id, bool isArchived) async {}

  @override
  Future<void> saveItem(ShoppingItem item) async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<void> toggleItemCompleted(String id, bool isCompleted) async {}

  @override
  Future<void> updateItemAmount(String id, int amount) async {}

  @override
  Future<List<String>> getProductSuggestions(String query, {int limit = 10}) async => const [];

  @override
  String exportToMarkdown(ShoppingList list) => ListFileHandler.exportToMarkdown(list);

  @override
  String exportToCsv(ShoppingList list) => ListFileHandler.exportToCsv(list);

  @override
  ShoppingList importFromContent({required String filename, required String content}) =>
      ListFileHandler.importFromContent(filename: filename, content: content);
}

void main() {
  group('Settings Persistence Tests', () {
    test('loads persisted theme mode, view mode, and completed expanded state', () async {
      final inMemorySettings = InMemorySettingsRepository(<String, String>{
        SettingsKeys.themeMode: 'dark',
        SettingsKeys.isGridView: '1',
        SettingsKeys.completedExpanded: '0',
      });

      final controller = ShoppingListsController(
        repository: _FakeShoppingListRepository(),
        settingsRepository: inMemorySettings,
      );

      await controller.loadSettings();

      expect(controller.themeMode, equals(ThemeMode.dark));
      expect(controller.isGridView, isTrue);
      expect(controller.isCompletedExpanded, isFalse);

      // Toggle theme mode to light and verify persisted value
      controller.toggleThemeMode();
      expect(controller.themeMode, equals(ThemeMode.light));

      final values = await inMemorySettings.loadAll();
      expect(values[SettingsKeys.themeMode], equals('light'));

      // Toggle grid view
      controller.toggleViewMode();
      expect(controller.isGridView, isFalse);
      final updatedValues = await inMemorySettings.loadAll();
      expect(updatedValues[SettingsKeys.isGridView], equals('0'));
    });
  });

  group('ShoppingItemTile with Stepper Tests', () {
    testWidgets('increments and decrements amount via stepper arrows', (WidgetTester tester) async {
      int updatedAmount = 1;

      final item = ShoppingItem(
        id: 'item-1',
        listId: 'list-1',
        name: 'Plátanos',
        amount: 2,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShoppingItemTile(
              item: item,
              palette: AppColors.getPalette(0),
              onToggleCompleted: (_) {},
              onAmountChanged: (int newAmount) {
                updatedAmount = newAmount;
              },
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Plátanos'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Tap Up arrow (keyboard_arrow_up_rounded)
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();
      expect(updatedAmount, equals(3));

      // Tap Down arrow (keyboard_arrow_down_rounded)
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();
      expect(updatedAmount, equals(1));
    });

    testWidgets('opens manual input dialog when tapping count and saves parsed integer',
        (WidgetTester tester) async {
      int updatedAmount = 1;

      final item = ShoppingItem(
        id: 'item-1',
        listId: 'list-1',
        name: 'Leche',
        amount: 1,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShoppingItemTile(
              item: item,
              palette: AppColors.getPalette(0),
              onToggleCompleted: (_) {},
              onAmountChanged: (int newAmount) {
                updatedAmount = newAmount;
              },
              onDelete: () {},
            ),
          ),
        ),
      );

      // Tap number to open dialog
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cantidad para "Leche"'), findsOneWidget);

      // Enter new amount '5'
      await tester.enterText(find.byType(TextField), '5');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(updatedAmount, equals(5));
    });
  });

  group('ListSeparatorTile Tests', () {
    testWidgets('renders separator label and triggers rename on tap', (WidgetTester tester) async {
      bool renameCalled = false;

      final separator = ShoppingItem(
        id: 'sep-1',
        listId: 'list-1',
        name: 'Bebidas y Refrescos',
        isSeparator: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListSeparatorTile(
              item: separator,
              palette: AppColors.getPalette(0),
              onRename: () {
                renameCalled = true;
              },
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Bebidas y Refrescos'), findsOneWidget);

      await tester.tap(find.text('Bebidas y Refrescos'));
      await tester.pumpAndSettle();

      expect(renameCalled, isTrue);
    });
  });

  group('Markdown Export/Import with Separators and Multipliers', () {
    test('exports and parses markdown with multipliers and separators', () {
      final now = DateTime.now();
      final list = ShoppingList(
        id: 'list-10',
        title: 'Fiesta',
        createdAt: now,
        updatedAt: now,
        items: <ShoppingItem>[
          ShoppingItem(id: 's1', listId: 'list-10', name: 'Bebidas', isSeparator: true, createdAt: now),
          ShoppingItem(id: 'i1', listId: 'list-10', name: 'Cervezas', amount: 6, createdAt: now),
          ShoppingItem(id: 'i2', listId: 'list-10', name: 'Hielo', quantity: '2 bolsas', createdAt: now),
        ],
      );

      final md = ListFileHandler.exportToMarkdown(list);
      expect(md, contains('--- Bebidas ---'));
      expect(md, contains('- [ ] 6x Cervezas'));
      expect(md, contains('- [ ] 2 bolsas Hielo'));

      final parsed = ListFileHandler.parseMarkdown(content: md);
      expect(parsed.items.length, equals(3));
      expect(parsed.items[0].isSeparator, isTrue);
      expect(parsed.items[0].name, equals('Bebidas'));
      expect(parsed.items[1].name, equals('Cervezas'));
      expect(parsed.items[1].amount, equals(6));
    });
  });
}
