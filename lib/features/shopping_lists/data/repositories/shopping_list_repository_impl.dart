import '../../domain/models/shopping_item.dart';
import '../../domain/models/shopping_list.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import '../datasources/shopping_list_local_datasource.dart';
import '../services/list_file_handler.dart';

/// Implementation of [ShoppingListRepository] combining SQLite persistence
/// and open-format file serialization.
class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final ShoppingListLocalDataSource localDataSource;

  ShoppingListRepositoryImpl({ShoppingListLocalDataSource? localDataSource})
    : localDataSource = localDataSource ?? ShoppingListLocalDataSource();

  @override
  Future<List<ShoppingList>> getAllLists({bool includeArchived = false}) {
    return localDataSource.getLists(includeArchived: includeArchived);
  }

  @override
  Future<ShoppingList?> getListById(String id) {
    return localDataSource.getListById(id);
  }

  @override
  Future<void> saveList(ShoppingList list) async {
    await localDataSource.saveList(list);
    for (final ShoppingItem item in list.items) {
      await localDataSource.saveItem(item);
    }
  }

  @override
  Future<void> deleteList(String id) {
    return localDataSource.deleteList(id);
  }

  @override
  Future<void> togglePinList(String id) {
    return localDataSource.togglePinList(id);
  }

  @override
  Future<void> setArchived(String id, bool isArchived) {
    return localDataSource.setArchived(id, isArchived);
  }

  @override
  Future<void> saveItem(ShoppingItem item) {
    return localDataSource.saveItem(item);
  }

  @override
  Future<void> deleteItem(String id) {
    return localDataSource.deleteItem(id);
  }

  @override
  Future<void> toggleItemCompleted(String id, bool isCompleted) {
    return localDataSource.toggleItemCompleted(id, isCompleted);
  }

  @override
  Future<void> updateItemAmount(String id, int amount) {
    return localDataSource.updateItemAmount(id, amount);
  }

  @override
  Future<List<String>> getProductSuggestions(String query, {int limit = 10}) {
    return localDataSource.getProductSuggestions(query, limit: limit);
  }

  @override
  String exportToMarkdown(ShoppingList list) {
    return ListFileHandler.exportToMarkdown(list);
  }

  @override
  String exportToCsv(ShoppingList list) {
    return ListFileHandler.exportToCsv(list);
  }

  @override
  ShoppingList importFromContent({
    required String filename,
    required String content,
  }) {
    return ListFileHandler.importFromContent(
      filename: filename,
      content: content,
    );
  }
}
