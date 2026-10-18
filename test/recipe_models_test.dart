import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/features/recipes/domain/models/recipe.dart';
import 'package:shopliist_pro/features/recipes/domain/models/recipe_ingredient.dart';

void main() {
  group('Recipe Models Tests', () {
    test('RecipeIngredient copyWith and serialization', () {
      const ingredient = RecipeIngredient(
        name: 'Spaghetti',
        measure: '500g',
        isSelected: true,
      );

      final modified = ingredient.copyWith(isSelected: false);
      expect(modified.name, 'Spaghetti');
      expect(modified.measure, '500g');
      expect(modified.isSelected, false);

      final map = modified.toMap();
      expect(map['name'], 'Spaghetti');
      expect(map['measure'], '500g');
      expect(map['isSelected'], 0);

      final restored = RecipeIngredient.fromMap(map);
      expect(restored, equals(modified));
    });

    test('Recipe copyWith and serialization', () {
      const ingredient1 = RecipeIngredient(name: 'Eggs', measure: '3');
      const ingredient2 = RecipeIngredient(
        name: 'Pecorino Romano',
        measure: '100g',
      );

      const recipe = Recipe(
        id: '52772',
        name: 'Carbonara',
        category: 'Pasta',
        area: 'Italian',
        instructions: 'Cook pasta, mix eggs and cheese, combine with pancetta.',
        thumbnailUrl: 'https://example.com/carbonara.jpg',
        ingredients: [ingredient1, ingredient2],
      );

      expect(recipe.ingredients.length, 2);

      final modified = recipe.copyWith(name: 'Spaghetti Carbonara Traditional');
      expect(modified.id, '52772');
      expect(modified.name, 'Spaghetti Carbonara Traditional');
      expect(modified.ingredients.length, 2);

      final map = modified.toMap();
      expect(map['id'], '52772');
      expect(map['name'], 'Spaghetti Carbonara Traditional');
      expect((map['ingredients'] as List).length, 2);

      final restored = Recipe.fromMap(map);
      expect(restored.id, recipe.id);
      expect(restored.name, 'Spaghetti Carbonara Traditional');
      expect(restored.ingredients.first.name, 'Eggs');
    });
  });
}
