class RecipeIngredient {
  final String name;
  final String measure;
  final bool isSelected;

  const RecipeIngredient({
    required this.name,
    this.measure = '',
    this.isSelected = true,
  });

  RecipeIngredient copyWith({String? name, String? measure, bool? isSelected}) {
    return RecipeIngredient(
      name: name ?? this.name,
      measure: measure ?? this.measure,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'measure': measure, 'isSelected': isSelected ? 1 : 0};
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      name: map['name'] as String? ?? '',
      measure: map['measure'] as String? ?? '',
      isSelected: (map['isSelected'] as int? ?? 1) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredient &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          measure == other.measure &&
          isSelected == other.isSelected;

  @override
  int get hashCode => name.hashCode ^ measure.hashCode ^ isSelected.hashCode;

  @override
  String toString() =>
      'RecipeIngredient(name: $name, measure: $measure, isSelected: $isSelected)';
}
