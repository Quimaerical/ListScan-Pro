import '../models/shopping_item.dart';
import '../models/shopping_list.dart';

/// Abstract contract for shopping list persistence and interoperability.
abstract class ShoppingListRepository {
  /// Fetches all active lists, optionally including archived ones.
  Future<List<ShoppingList>> getAllLists({bool includeArchived = false});

  /// Retrieves a specific shopping list including its items by its [id].
  Future<ShoppingList?> getListById(String id);

  /// Inserts or updates a [ShoppingList] header.
  Future<void> saveList(ShoppingList list);

  /// Permanently removes a shopping list and cascades to all its items.
  Future<void> deleteList(String id);

  /// Toggles the pinned status of a list.
  Future<void> togglePinList(String id);

  /// Updates archive status for a given list.
  Future<void> setArchived(String id, bool isArchived);

  /// Persists plain text recipe or general notes for a given list.
  Future<void> updateListNotes(String id, String? notes);

  /// Inserts or updates an individual [ShoppingItem].
  Future<void> saveItem(ShoppingItem item);

  /// Deletes an item by its [id].
  Future<void> deleteItem(String id);

  /// Toggles the completed status of an item.
  Future<void> toggleItemCompleted(String id, bool isCompleted);

  /// Persists the integer counter of an item (clamped to a valid range).
  Future<void> updateItemAmount(String id, int amount);

  /// Persists the unit price of an item (or clears it if null).
  Future<void> updateItemPrice(String id, double? price);

  /// Returns distinct item names matching the given [query] for autocomplete.
  Future<List<String>> getProductSuggestions(String query, {int limit = 10});

  /// Serializes a [ShoppingList] into standard GitHub / Obsidian checklist Markdown (.md).
  String exportToMarkdown(ShoppingList list, {bool includeNotes = false});

  /// Serializes a [ShoppingList] into standard CSV (RFC 4180).
  String exportToCsv(ShoppingList list, {bool includeNotes = false});

  /// Parses file contents (.md or .csv) and returns a hydrated [ShoppingList] entity.
  ShoppingList importFromContent({
    required String filename,
    required String content,
  });
}
