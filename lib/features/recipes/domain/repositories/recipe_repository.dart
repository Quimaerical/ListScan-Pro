import '../models/recipe.dart';

abstract class RecipeRepository {
  Future<List<Recipe>> searchRecipes(String query);
  Future<Recipe?> getRecipeById(String id);
}
