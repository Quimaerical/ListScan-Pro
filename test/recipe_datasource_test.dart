import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shopliist_pro/core/network/api_client.dart';
import 'package:shopliist_pro/features/recipes/data/datasources/mealdb_remote_data_source.dart';
import 'package:shopliist_pro/features/recipes/data/repositories/recipe_repository_impl.dart';

void main() {
  group('MealDbRemoteDataSource & Parser Tests', () {
    final sampleMealJson = {
      'idMeal': '52772',
      'strMeal': 'Teriyaki Chicken Casserole',
      'strCategory': 'Chicken',
      'strArea': 'Japanese',
      'strInstructions': 'Bake in oven.',
      'strMealThumb': 'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
      'strIngredient1': 'soy sauce',
      'strIngredient2': 'water',
      'strIngredient3': 'brown sugar',
      'strIngredient4': '',
      'strIngredient5': '   ',
      'strIngredient6': null,
      'strMeasure1': '3/4 cup',
      'strMeasure2': '1/2 cup',
      'strMeasure3': '1/4 cup',
      'strMeasure4': '',
      'strMeasure5': '',
      'strMeasure6': null,
    };

    test('parseRecipeFromMealDb correctly extracts only valid 1..20 ingredients and measures', () {
      final recipe = MealDbRemoteDataSource.parseRecipeFromMealDb(sampleMealJson);

      expect(recipe.id, '52772');
      expect(recipe.name, 'Teriyaki Chicken Casserole');
      expect(recipe.category, 'Chicken');
      expect(recipe.area, 'Japanese');
      expect(recipe.thumbnailUrl, contains('wvpsxx1468256321.jpg'));

      expect(recipe.ingredients.length, 3);
      expect(recipe.ingredients[0].name, 'soy sauce');
      expect(recipe.ingredients[0].measure, '3/4 cup');
      expect(recipe.ingredients[1].name, 'water');
      expect(recipe.ingredients[1].measure, '1/2 cup');
      expect(recipe.ingredients[2].name, 'brown sugar');
      expect(recipe.ingredients[2].measure, '1/4 cup');
    });

    test('searchRecipes returns parsed recipes when API returns meals', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/search.php');
        expect(request.url.queryParameters['s'], 'chicken');
        return http.Response(
          jsonEncode({
            'meals': [sampleMealJson],
          }),
          200,
        );
      });

      final apiClient = ApiClient(baseUrl: 'https://test.api', client: mockClient);
      final dataSource = MealDbRemoteDataSource(client: apiClient);
      final repo = RecipeRepositoryImpl(remoteDataSource: dataSource);

      final results = await repo.searchRecipes('chicken');
      expect(results.length, 1);
      expect(results.first.name, 'Teriyaki Chicken Casserole');
    });

    test('searchRecipes returns empty list when API returns null meals (no matches)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'meals': null}),
          200,
        );
      });

      final apiClient = ApiClient(baseUrl: 'https://test.api', client: mockClient);
      final dataSource = MealDbRemoteDataSource(client: apiClient);
      final repo = RecipeRepositoryImpl(remoteDataSource: dataSource);

      final results = await repo.searchRecipes('nonexistentdish123');
      expect(results, isEmpty);
    });

    test('getRecipeById returns recipe or null if not found', () async {
      final mockClient = MockClient((request) async {
        if (request.url.queryParameters['i'] == '52772') {
          return http.Response(
            jsonEncode({
              'meals': [sampleMealJson],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'meals': null}), 200);
      });

      final apiClient = ApiClient(baseUrl: 'https://test.api', client: mockClient);
      final dataSource = MealDbRemoteDataSource(client: apiClient);
      final repo = RecipeRepositoryImpl(remoteDataSource: dataSource);

      final recipe = await repo.getRecipeById('52772');
      expect(recipe, isNotNull);
      expect(recipe!.id, '52772');

      final nullRecipe = await repo.getRecipeById('99999');
      expect(nullRecipe, isNull);
    });
  });
}
