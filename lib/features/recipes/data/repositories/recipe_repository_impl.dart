import '../../../settings/domain/repositories/settings_repository.dart';
import '../../domain/models/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/forkify_remote_data_source.dart';
import '../datasources/mealdb_remote_data_source.dart';
import '../services/recipe_query_normalizer.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final MealDbRemoteDataSource remoteDataSource;
  final ForkifyRemoteDataSource? forkifyDataSource;
  final SettingsRepository? settingsRepository;

  RecipeRepositoryImpl({
    MealDbRemoteDataSource? remoteDataSource,
    ForkifyRemoteDataSource? forkifyDataSource,
    this.settingsRepository,
  }) : remoteDataSource = remoteDataSource ?? MealDbRemoteDataSource(),
       forkifyDataSource =
           forkifyDataSource ??
           (remoteDataSource == null ? ForkifyRemoteDataSource() : null);

  @override
  Future<List<Recipe>> searchRecipes(String query) async {
    final String clean = query.trim();
    if (clean.isEmpty) return const <Recipe>[];

    final List<String> queries = RecipeQueryNormalizer.expandQuery(clean);

    bool mealDbEnabled = true;
    bool forkifyEnabled = forkifyDataSource != null;

    if (settingsRepository != null) {
      try {
        final Map<String, String> settings = await settingsRepository!
            .loadAll();
        mealDbEnabled = settings[SettingsKeys.enableTheMealDb] != '0';
        forkifyEnabled =
            forkifyDataSource != null &&
            settings[SettingsKeys.enableAsianRecipes] != '0';
      } catch (_) {
        // Fall back to default enabled
      }
    }

    final List<Future<List<Recipe>>> futures = <Future<List<Recipe>>>[];
    final List<String> searchTerms = queries.take(3).toList();

    if (mealDbEnabled) {
      for (final String term in searchTerms) {
        futures.add(
          remoteDataSource
              .searchRecipes(term)
              .catchError((_) => const <Recipe>[]),
        );
      }
    }

    if (forkifyEnabled && forkifyDataSource != null) {
      for (final String term in searchTerms) {
        futures.add(
          forkifyDataSource!
              .searchRecipes(term)
              .catchError((_) => const <Recipe>[]),
        );
      }
    }

    final List<List<Recipe>> resultsList = await Future.wait(futures);
    final Set<String> seen = <String>{};
    final List<Recipe> combined = <Recipe>[];

    for (final List<Recipe> list in resultsList) {
      for (final Recipe recipe in list) {
        final String key = recipe.name.toLowerCase().trim();
        if (key.isNotEmpty && seen.add(key)) {
          combined.add(recipe);
        }
      }
    }

    return combined;
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    try {
      final Recipe? meal = await remoteDataSource.getRecipeById(id);
      if (meal != null) return meal;
    } catch (_) {}

    if (forkifyDataSource != null) {
      try {
        final Recipe? forkifyRecipe = await forkifyDataSource!.getRecipeById(
          id,
        );
        if (forkifyRecipe != null) return forkifyRecipe;
      } catch (_) {}
    }

    return null;
  }
}
