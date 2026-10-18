import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/theme/app_colors.dart';
import 'package:shopliist_pro/features/recipes/domain/models/recipe.dart';
import 'package:shopliist_pro/features/recipes/domain/models/recipe_ingredient.dart';
import 'package:shopliist_pro/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:shopliist_pro/features/recipes/presentation/controllers/recipe_search_controller.dart';
import 'package:shopliist_pro/features/recipes/presentation/views/recipe_search_screen.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_item.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_list.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/controllers/shopping_lists_controller.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/quick_add_bar.dart';

class MockFullShoppingListRepository implements ShoppingListRepository {
  final List<ShoppingList> _lists = [];
  final List<String> suggestions = [
    'Manzanas Rojas',
    'Mantequilla',
    'Mandarinas',
  ];

  @override
  Future<List<ShoppingList>> getAllLists({
    bool includeArchived = false,
  }) async => _lists;

  @override
  Future<ShoppingList?> getListById(String id) async =>
      _lists.where((l) => l.id == id).firstOrNull;

  @override
  Future<void> saveList(ShoppingList list) async {
    _lists.removeWhere((l) => l.id == list.id);
    _lists.add(list);
  }

  @override
  Future<void> deleteList(String id) async {
    _lists.removeWhere((l) => l.id == id);
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
  Future<List<String>> getProductSuggestions(
    String query, {
    int limit = 10,
  }) async {
    final clean = query.toLowerCase();
    return suggestions.where((s) => s.toLowerCase().contains(clean)).toList();
  }

  @override
  String exportToMarkdown(ShoppingList list) => '';

  @override
  String exportToCsv(ShoppingList list) => '';

  @override
  ShoppingList importFromContent({
    required String filename,
    required String content,
  }) {
    return ShoppingList(
      id: 'mock-1',
      title: 'Mock',
      colorIndex: 0,
      isPinned: false,
      isArchived: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class MockFullRecipeRepository implements RecipeRepository {
  @override
  Future<List<Recipe>> searchRecipes(String query) async {
    return [
      const Recipe(
        id: '1',
        name: 'Pasta Bolognese',
        category: 'Pasta',
        area: 'Italian',
        instructions: 'Cook and enjoy.',
        ingredients: [
          RecipeIngredient(name: 'Minced Meat', measure: '400g'),
          RecipeIngredient(name: 'Tomato Sauce', measure: '1 can'),
        ],
      ),
    ];
  }

  @override
  Future<Recipe?> getRecipeById(String id) async => null;
}

void main() {
  group('QuickAddBar Autocomplete Tests', () {
    testWidgets('shows autocomplete chips when typing and adds on chip tap', (
      tester,
    ) async {
      String? addedName;
      String? addedQty;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddBar(
              palette: AppColors.palettes.first,
              onFetchSuggestions: (query) async {
                if (query == 'man') {
                  return ['Manzanas', 'Mantequilla'];
                }
                return [];
              },
              onAdd: (name, qty) {
                addedName = name;
                addedQty = qty;
              },
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Type "man" into TextField
      await tester.enterText(textFieldFinder, 'man');
      await tester.pump(const Duration(milliseconds: 300)); // debounce timer
      await tester.pumpAndSettle();

      // Check chips appear
      expect(find.text('Manzanas'), findsOneWidget);
      expect(find.text('Mantequilla'), findsOneWidget);

      // Tap suggestion chip
      await tester.tap(find.text('Manzanas'));
      await tester.pumpAndSettle();

      expect(addedName, 'Manzanas');
      expect(addedQty, isNull);
    });
  });

  group('RecipeSearchScreen Widget Tests', () {
    testWidgets('renders search field, category chips, and performs search', (
      tester,
    ) async {
      final shoppingRepo = MockFullShoppingListRepository();
      final shoppingController = ShoppingListsController(
        repository: shoppingRepo,
      );
      final recipeRepo = MockFullRecipeRepository();
      final recipeController = RecipeSearchController(repository: recipeRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: RecipeSearchScreen(
            shoppingListsController: shoppingController,
            recipeSearchController: recipeController,
          ),
        ),
      );

      expect(find.text('Explorar Recetas'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);

      // Tap "Pasta" chip to trigger search
      await tester.ensureVisible(find.text('Pasta'));
      await tester.tap(find.text('Pasta'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Pasta Bolognese'), findsOneWidget);
      expect(find.text('2 ingredientes'), findsOneWidget);
    });
  });
}
