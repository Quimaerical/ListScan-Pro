import 'shopping_item.dart';

/// Represents a shopping list container with associated metadata and item collection.
class ShoppingList {
  final String id;
  final String title;
  final int colorIndex;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShoppingItem> items;

  const ShoppingList({
    required this.id,
    required this.title,
    this.colorIndex = 0,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.items = const <ShoppingItem>[],
  });

  /// Real products only — separators are purely visual and never counted.
  Iterable<ShoppingItem> get products =>
      items.where((ShoppingItem item) => !item.isSeparator);

  int get totalCount => products.length;

  int get completedCount =>
      products.where((ShoppingItem item) => item.isCompleted).length;

  int get pendingCount => totalCount - completedCount;

  double get progressPercentage {
    if (totalCount == 0) return 0.0;
    return completedCount / totalCount;
  }

  /// Total cumulative price of all priced products in the list.
  double get totalPrice => products.fold<double>(
        0.0,
        (double acc, ShoppingItem item) =>
            item.price == null ? acc : acc + (item.totalLinePrice ?? 0.0),
      );

  /// Whether at least one product in the list has an assigned price.
  bool get hasPrices =>
      products.any((ShoppingItem item) => item.price != null);

  ShoppingList copyWith({
    String? id,
    String? title,
    int? colorIndex,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ShoppingItem>? items,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      title: title ?? this.title,
      colorIndex: colorIndex ?? this.colorIndex,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'color_index': colorIndex,
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ShoppingList.fromMap(
    Map<String, dynamic> map, [
    List<ShoppingItem> items = const <ShoppingItem>[],
  ]) {
    return ShoppingList(
      id: map['id'] as String,
      title: map['title'] as String,
      colorIndex: map['color_index'] as int? ?? 0,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
      items: items,
    );
  }
}
