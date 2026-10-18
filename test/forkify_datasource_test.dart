import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shopliist_pro/core/network/api_client.dart';
import 'package:shopliist_pro/features/recipes/data/datasources/forkify_remote_data_source.dart';

void main() {
  group('ForkifyRemoteDataSource', () {
    test('searchRecipes returns parsed recipes from Forkify API', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'results': 2,
            'data': {
              'recipes': [
                {
                  'id': 'rec_1',
                  'title': 'Japanese Tonkotsu Ramen',
                  'publisher': 'Just One Cookbook',
                  'image_url': 'https://example.com/ramen.jpg',
                },
                {
                  'id': 'rec_2',
                  'title': 'Spicy Pork Gyoza',
                  'publisher': 'Woks of Life',
                  'image_url': 'https://example.com/gyoza.jpg',
                },
              ],
            },
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://test.forkify',
        client: mockClient,
      );
      final dataSource = ForkifyRemoteDataSource(client: apiClient);

      final results = await dataSource.searchRecipes('ramen');
      expect(results.length, 2);
      expect(results[0].id, 'rec_1');
      expect(results[0].name, 'Japanese Tonkotsu Ramen');
      expect(results[0].area, 'Just One Cookbook');
      expect(results[0].category, 'Asiática / Internacional');
      expect(results[1].id, 'rec_2');
      expect(results[1].name, 'Spicy Pork Gyoza');
    });

    test(
      'getRecipeById returns recipe with full ingredients and instructions',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'recipe': {
                  'id': 'rec_1',
                  'title': 'Authentic Chicken Curry &amp; Rice',
                  'publisher': 'BBC Good Food',
                  'source_url': 'https://bbcgoodfood.com/curry',
                  'image_url': 'https://example.com/curry.jpg',
                  'servings': 4,
                  'cooking_time': 45,
                  'ingredients': [
                    {
                      'quantity': 500,
                      'unit': 'g',
                      'description': 'chicken breast diced',
                    },
                    {
                      'quantity': 2,
                      'unit': 'tbsp',
                      'description': 'curry powder',
                    },
                    {
                      'quantity': null,
                      'unit': '',
                      'description': 'fresh coriander to garnish',
                    },
                  ],
                },
              },
            }),
            200,
          );
        });

        final apiClient = ApiClient(
          baseUrl: 'https://test.forkify',
          client: mockClient,
        );
        final dataSource = ForkifyRemoteDataSource(client: apiClient);

        final recipe = await dataSource.getRecipeById('rec_1');
        expect(recipe, isNotNull);
        expect(recipe!.name, 'Authentic Chicken Curry & Rice');
        expect(recipe.ingredients.length, 3);
        expect(recipe.ingredients[0].name, 'chicken breast diced');
        expect(recipe.ingredients[0].measure, '500 g');
        expect(recipe.ingredients[1].measure, '2 tbsp');
        expect(recipe.ingredients[2].measure, '');
        expect(recipe.instructions, contains('Porciones: 4'));
        expect(recipe.instructions, contains('Tiempo estimado: 45 min'));
      },
    );

    test('handles empty or error response gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://test.forkify',
        client: mockClient,
      );
      final dataSource = ForkifyRemoteDataSource(client: apiClient);

      final searchResults = await dataSource.searchRecipes('fail');
      expect(searchResults, isEmpty);

      final recipeDetail = await dataSource.getRecipeById('fail');
      expect(recipeDetail, isNull);
    });
  });
}
