/// Represents an individual item within a shopping list.
class ShoppingItem {
  final String id;
  final String listId;
  final String name;
  final String? quantity;
  final String? category;
  final bool isCompleted;
  final int sortOrder;
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity,
    this.category,
    this.isCompleted = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    String? quantity,
    String? category,
    bool? isCompleted,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'category': category,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as String,
      listId: map['list_id'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as String?,
      category: map['category'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingItem &&
        other.id == id &&
        other.listId == listId &&
        other.name == name &&
        other.quantity == quantity &&
        other.category == category &&
        other.isCompleted == isCompleted &&
        other.sortOrder == sortOrder &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        listId,
        name,
        quantity,
        category,
        isCompleted,
        sortOrder,
        createdAt,
      );
}
