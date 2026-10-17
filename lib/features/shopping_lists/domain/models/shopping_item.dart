/// Represents an individual entry within a shopping list.
///
/// An entry is either a regular **product** (with checkbox and integer
/// counter) or a **separator** ([isSeparator] = `true`): a visual divider
/// with an optional label that never counts towards progress or totals.
class ShoppingItem {
  /// Lower and upper bounds for the integer counter shown on each product.
  static const int minAmount = 1;
  static const int maxAmount = 9999;

  final String id;
  final String listId;
  final String name;

  /// Free-text detail (e.g. "2 kg", "500 g", "Marca X"). Optional.
  final String? quantity;
  final String? category;

  /// Integer counter controlled by the ▲/▼ stepper. Always >= [minAmount].
  final int amount;

  /// When `true`, this entry is a named divider rather than a product.
  final bool isSeparator;

  final bool isCompleted;
  final int sortOrder;
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity,
    this.category,
    this.amount = 1,
    this.isSeparator = false,
    this.isCompleted = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  /// Clamps any incoming integer into the valid counter range.
  static int clampAmount(int value) => value.clamp(minAmount, maxAmount);

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    String? quantity,
    String? category,
    int? amount,
    bool? isSeparator,
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
      amount: amount ?? this.amount,
      isSeparator: isSeparator ?? this.isSeparator,
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
      'amount': amount,
      'is_separator': isSeparator ? 1 : 0,
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
      amount: clampAmount(map['amount'] as int? ?? 1),
      isSeparator: (map['is_separator'] as int? ?? 0) == 1,
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
        other.amount == amount &&
        other.isSeparator == isSeparator &&
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
        amount,
        isSeparator,
        isCompleted,
        sortOrder,
        createdAt,
      );
}
