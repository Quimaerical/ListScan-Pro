import '../../../../core/config/endpoint_security.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/recipe_ingredient.dart';

class MealDbRemoteDataSource {
  final ApiClient _client;

  MealDbRemoteDataSource({ApiClient? client})
      : _client = client ??
            ApiClient(baseUrl: EndpointSecurity.getMealDbBaseUrl());

  /// Searches meals by name query.
  /// An empty query string searches for default recipes on TheMealDB.
  Future<List<Recipe>> searchRecipes(String query) async {
    final response = await _client.get(
      'search.php',
      queryParameters: {'s': query},
    );

    if (response == null || response is! Map<String, dynamic>) {
      return const [];
    }

    final rawMeals = response['meals'];
    if (rawMeals == null || rawMeals is! List) {
      return const [];
    }

    return rawMeals
        .whereType<Map<String, dynamic>>()
        .map(parseRecipeFromMealDb)
        .toList();
  }

  /// Fetches a specific meal by ID.
  Future<Recipe?> getRecipeById(String id) async {
    final response = await _client.get(
      'lookup.php',
      queryParameters: {'i': id},
    );

    if (response == null || response is! Map<String, dynamic>) {
      return null;
    }

    final rawMeals = response['meals'];
    if (rawMeals == null || rawMeals is! List || rawMeals.isEmpty) {
      return null;
    }

    final firstMeal = rawMeals.first;
    if (firstMeal is! Map<String, dynamic>) {
      return null;
    }

    return parseRecipeFromMealDb(firstMeal);
  }

  /// Dynamic unrolled parser for TheMealDB recipes extracting strIngredient1..20
  /// and strMeasure1..20, discarding null or empty values.
  static Recipe parseRecipeFromMealDb(Map<String, dynamic> json) {
    final ingredients = <RecipeIngredient>[];

    for (int i = 1; i <= 20; i++) {
      final dynamic rawIngredient = json['strIngredient$i'];
      if (rawIngredient != null && rawIngredient is String) {
        final trimmedName = rawIngredient.trim();
        if (trimmedName.isNotEmpty) {
          final dynamic rawMeasure = json['strMeasure$i'];
          final trimmedMeasure = (rawMeasure != null && rawMeasure is String)
              ? rawMeasure.trim()
              : '';

          ingredients.add(
            RecipeIngredient(
              name: trimmedName,
              measure: trimmedMeasure,
              isSelected: true,
            ),
          );
        }
      }
    }

    return Recipe(
      id: json['idMeal']?.toString() ?? '',
      name: json['strMeal']?.toString() ?? '',
      category: json['strCategory']?.toString(),
      area: json['strArea']?.toString(),
      instructions: json['strInstructions']?.toString(),
      thumbnailUrl: json['strMealThumb']?.toString(),
      ingredients: ingredients,
    );
  }
}
