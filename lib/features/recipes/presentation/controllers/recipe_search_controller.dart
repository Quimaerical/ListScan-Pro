import 'package:flutter/foundation.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/recipe_ingredient.dart';
import '../../domain/repositories/recipe_repository.dart';

enum RecipeSearchStatus { initial, loading, success, empty, error }

class RecipeSearchController extends ChangeNotifier {
  final RecipeRepository repository;

  RecipeSearchController({required this.repository});

  RecipeSearchStatus _status = RecipeSearchStatus.initial;
  RecipeSearchStatus get status => _status;

  String _query = '';
  String get query => _query;

  List<Recipe> _recipes = [];
  List<Recipe> get recipes => List.unmodifiable(_recipes);

  Recipe? _selectedRecipe;
  Recipe? get selectedRecipe => _selectedRecipe;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == RecipeSearchStatus.loading;

  Future<void> search(String query) async {
    final trimmed = query.trim();
    _query = trimmed;

    if (trimmed.isEmpty) {
      _recipes = [];
      _status = RecipeSearchStatus.initial;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _status = RecipeSearchStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await repository.searchRecipes(trimmed);
      _recipes = results;
      if (results.isEmpty) {
        _status = RecipeSearchStatus.empty;
      } else {
        _status = RecipeSearchStatus.success;
      }
    } on ApiException catch (e) {
      _status = RecipeSearchStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = RecipeSearchStatus.error;
      _errorMessage = 'No se pudieron cargar las recetas: $e';
    } finally {
      notifyListeners();
    }
  }

  void selectRecipe(Recipe recipe) {
    // Default all ingredients to selected when opened
    final defaultIngredients = recipe.ingredients
        .map((item) => item.copyWith(isSelected: true))
        .toList();
    _selectedRecipe = recipe.copyWith(ingredients: defaultIngredients);
    notifyListeners();
  }

  void clearSelection() {
    _selectedRecipe = null;
    notifyListeners();
  }

  void toggleIngredient(int index) {
    if (_selectedRecipe == null) return;
    if (index < 0 || index >= _selectedRecipe!.ingredients.length) return;

    final updated = List<RecipeIngredient>.from(_selectedRecipe!.ingredients);
    final current = updated[index];
    updated[index] = current.copyWith(isSelected: !current.isSelected);

    _selectedRecipe = _selectedRecipe!.copyWith(ingredients: updated);
    notifyListeners();
  }

  void toggleAllIngredients(bool selectAll) {
    if (_selectedRecipe == null) return;

    final updated = _selectedRecipe!.ingredients
        .map((item) => item.copyWith(isSelected: selectAll))
        .toList();

    _selectedRecipe = _selectedRecipe!.copyWith(ingredients: updated);
    notifyListeners();
  }

  List<RecipeIngredient> getSelectedIngredients() {
    if (_selectedRecipe == null) return const [];
    return _selectedRecipe!.ingredients.where((i) => i.isSelected).toList();
  }
}
