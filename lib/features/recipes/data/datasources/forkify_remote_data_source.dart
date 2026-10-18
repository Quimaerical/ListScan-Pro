import '../../../../core/config/endpoint_security.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/recipe_ingredient.dart';

/// Remote data source for Forkify Open API (over 1,000,000 recipes with high
/// coverage of Asian, European, and International dishes, with zero API key required).
class ForkifyRemoteDataSource {
  final ApiClient _client;

  ForkifyRemoteDataSource({ApiClient? client})
    : _client =
          client ?? ApiClient(baseUrl: EndpointSecurity.getForkifyBaseUrl());

  /// Searches recipes by keyword. Returns a list of recipes (without ingredients
  /// loaded; full ingredient breakdown is fetched via [getRecipeById]).
  Future<List<Recipe>> searchRecipes(String query) async {
    final String clean = query.trim();
    if (clean.isEmpty) return const <Recipe>[];

    try {
      final dynamic response = await _client.get(
        '',
        queryParameters: <String, dynamic>{'search': clean},
      );

      if (response == null || response is! Map<String, dynamic>) {
        return const <Recipe>[];
      }

      final dynamic data = response['data'];
      if (data == null || data is! Map<String, dynamic>) {
        return const <Recipe>[];
      }

      final dynamic rawRecipes = data['recipes'];
      if (rawRecipes == null || rawRecipes is! List) {
        return const <Recipe>[];
      }

      return rawRecipes
          .whereType<Map<String, dynamic>>()
          .map(_parseRecipeSummary)
          .toList();
    } catch (_) {
      // Graceful degradation when network/endpoint is unavailable
      return const <Recipe>[];
    }
  }

  /// Fetches complete recipe details including ingredients, servings, and source.
  Future<Recipe?> getRecipeById(String id) async {
    final String cleanId = id.trim();
    if (cleanId.isEmpty) return null;

    try {
      final dynamic response = await _client.get(cleanId);
      if (response == null || response is! Map<String, dynamic>) {
        return null;
      }

      final dynamic data = response['data'];
      if (data == null || data is! Map<String, dynamic>) {
        return null;
      }

      final dynamic rawRecipe = data['recipe'];
      if (rawRecipe == null || rawRecipe is! Map<String, dynamic>) {
        return null;
      }

      return _parseRecipeDetail(rawRecipe);
    } catch (_) {
      return null;
    }
  }

  static Recipe _parseRecipeSummary(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      name: _cleanHtmlEntities(json['title']?.toString() ?? ''),
      category: 'Asiática / Internacional',
      area: json['publisher']?.toString() ?? 'Receta Global',
      thumbnailUrl: json['image_url']?.toString(),
      ingredients: const <RecipeIngredient>[],
    );
  }

  static Recipe _parseRecipeDetail(Map<String, dynamic> json) {
    final List<RecipeIngredient> ingredients = <RecipeIngredient>[];

    final dynamic rawIngredients = json['ingredients'];
    if (rawIngredients is List) {
      for (final dynamic item in rawIngredients) {
        if (item is Map<String, dynamic>) {
          final dynamic rawQty = item['quantity'];
          final String unit = (item['unit']?.toString() ?? '').trim();
          final String desc = _cleanHtmlEntities(
            (item['description']?.toString() ?? '').trim(),
          );

          final List<String> measureParts = <String>[];
          if (rawQty != null && rawQty is num && rawQty > 0) {
            if (rawQty == rawQty.roundToDouble()) {
              measureParts.add(rawQty.toInt().toString());
            } else {
              measureParts.add(rawQty.toStringAsFixed(1));
            }
          }
          if (unit.isNotEmpty) {
            measureParts.add(unit);
          }

          if (desc.isNotEmpty) {
            ingredients.add(
              RecipeIngredient(
                name: desc,
                measure: measureParts.join(' ').trim(),
                isSelected: true,
              ),
            );
          }
        }
      }
    }

    final String? sourceUrl = json['source_url']?.toString();
    final dynamic servings = json['servings'];
    final dynamic cookingTime = json['cooking_time'];

    final StringBuffer instructions = StringBuffer();
    if (servings != null) {
      instructions.writeln('Porciones: $servings');
    }
    if (cookingTime != null) {
      instructions.writeln('Tiempo estimado: $cookingTime min');
    }
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      instructions.writeln('Fuente: $sourceUrl');
    }

    return Recipe(
      id: json['id']?.toString() ?? '',
      name: _cleanHtmlEntities(json['title']?.toString() ?? ''),
      category: 'Asiática / Internacional',
      area: json['publisher']?.toString() ?? 'Receta Global',
      instructions: instructions.toString().trim(),
      thumbnailUrl: json['image_url']?.toString(),
      ingredients: ingredients,
    );
  }

  static String _cleanHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }
}
