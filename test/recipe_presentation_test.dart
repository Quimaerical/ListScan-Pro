import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/network/api_exceptions.dart';
import 'package:shopliist_pro/features/recipes/domain/models/recipe.dart';
import 'package:shopliist_pro/features/recipes/domain/models/recipe_ingredient.dart';
import 'package:shopliist_pro/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:shopliist_pro/features/recipes/presentation/controllers/recipe_search_controller.dart';
import 'package:shopliist_pro/features/recipes/presentation/widgets/recipe_card.dart';

class MockRecipeRepository implements RecipeRepository {
  List<Recipe> searchResults = [];
  Exception? errorToThrow;

  @override
  Future<List<Recipe>> searchRecipes(String query) async {
    if (errorToThrow != null) throw errorToThrow!;
    return searchResults;
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    return searchResults.where((r) => r.id == id).firstOrNull;
  }
}

void main() {
  const sampleRecipe = Recipe(
    id: '123',
    name: 'Spaghetti Carbonara',
    category: 'Pasta',
    area: 'Italian',
    instructions: 'Boil water and cook pasta.',
    ingredients: [
      RecipeIngredient(name: 'Spaghetti', measure: '500g'),
      RecipeIngredient(name: 'Eggs', measure: '3'),
      RecipeIngredient(name: 'Bacon', measure: '150g'),
    ],
  );

  group('RecipeSearchController Tests', () {
    test('initial state is correct', () {
      final repo = MockRecipeRepository();
      final controller = RecipeSearchController(repository: repo);

      expect(controller.status, RecipeSearchStatus.initial);
      expect(controller.recipes, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('search updates status to success when results exist', () async {
      final repo = MockRecipeRepository();
      repo.searchResults = [sampleRecipe];
      final controller = RecipeSearchController(repository: repo);

      await controller.search('pasta');

      expect(controller.status, RecipeSearchStatus.success);
      expect(controller.recipes.length, 1);
      expect(controller.recipes.first.name, 'Spaghetti Carbonara');
    });

    test('search updates status to empty when 0 results returned', () async {
      final repo = MockRecipeRepository();
      repo.searchResults = [];
      final controller = RecipeSearchController(repository: repo);

      await controller.search('nonexistent');

      expect(controller.status, RecipeSearchStatus.empty);
      expect(controller.recipes, isEmpty);
    });

    test('search updates status to error on ApiException', () async {
      final repo = MockRecipeRepository();
      repo.errorToThrow = const NetworkException('No internet');
      final controller = RecipeSearchController(repository: repo);

      await controller.search('pasta');

      expect(controller.status, RecipeSearchStatus.error);
      expect(controller.errorMessage, 'No internet');
    });

    test('ingredient selection toggling works properly', () {
      final repo = MockRecipeRepository();
      final controller = RecipeSearchController(repository: repo);

      controller.selectRecipe(sampleRecipe);
      expect(controller.selectedRecipe, isNotNull);
      expect(controller.getSelectedIngredients().length, 3);

      // Toggle first ingredient off
      controller.toggleIngredient(0);
      expect(controller.getSelectedIngredients().length, 2);
      expect(controller.getSelectedIngredients().first.name, 'Eggs');

      // Toggle all off
      controller.toggleAllIngredients(false);
      expect(controller.getSelectedIngredients(), isEmpty);

      // Toggle all on
      controller.toggleAllIngredients(true);
      expect(controller.getSelectedIngredients().length, 3);
    });
  });

  group('RecipeCard Widget Tests', () {
    testWidgets('renders title, category, area and ingredient count', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeCard(
              recipe: sampleRecipe,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Spaghetti Carbonara'), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Italian'), findsOneWidget);
      expect(find.text('3 ingredientes'), findsOneWidget);

      await tester.tap(find.byType(RecipeCard));
      expect(tapped, isTrue);
    });
  });
}
