import 'recipe_ingredient.dart';

class Recipe {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String? instructions;
  final String? thumbnailUrl;
  final List<RecipeIngredient> ingredients;

  const Recipe({
    required this.id,
    required this.name,
    this.category,
    this.area,
    this.instructions,
    this.thumbnailUrl,
    this.ingredients = const [],
  });

  Recipe copyWith({
    String? id,
    String? name,
    String? category,
    String? area,
    String? instructions,
    String? thumbnailUrl,
    List<RecipeIngredient>? ingredients,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      area: area ?? this.area,
      instructions: instructions ?? this.instructions,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'area': area,
      'instructions': instructions,
      'thumbnailUrl': thumbnailUrl,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String?,
      area: map['area'] as String?,
      instructions: map['instructions'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      ingredients:
          (map['ingredients'] as List<dynamic>?)
              ?.map(
                (item) =>
                    RecipeIngredient.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          area == other.area &&
          thumbnailUrl == other.thumbnailUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      category.hashCode ^
      area.hashCode ^
      thumbnailUrl.hashCode;

  @override
  String toString() =>
      'Recipe(id: $id, name: $name, category: $category, area: $area, ingredients: ${ingredients.length})';
}
