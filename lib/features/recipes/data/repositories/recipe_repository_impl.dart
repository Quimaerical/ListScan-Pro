import '../../domain/models/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/mealdb_remote_data_source.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final MealDbRemoteDataSource remoteDataSource;

  RecipeRepositoryImpl({MealDbRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? MealDbRemoteDataSource();

  @override
  Future<List<Recipe>> searchRecipes(String query) async {
    return remoteDataSource.searchRecipes(query);
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    return remoteDataSource.getRecipeById(id);
  }
}
