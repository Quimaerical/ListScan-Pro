import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/shopping_item.dart';
import '../../domain/models/shopping_list.dart';
import '../../domain/repositories/shopping_list_repository.dart';

/// Central state controller managing shopping lists, view modes, themes and search filters
/// using Flutter's native [ChangeNotifier] for ultra-responsive performance.
class ShoppingListsController extends ChangeNotifier {
  final ShoppingListRepository repository;
  static const Uuid _uuid = Uuid();

  ShoppingListsController({required this.repository});

  List<ShoppingList> _lists = <ShoppingList>[];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _isGridView = false; // Default: structured vertical list
  ThemeMode _themeMode = ThemeMode.light;
  int _selectedFilterIndex = 0; // 0: Todas, 1: Con pendientes, 2: Archivadas

  // Getters
  List<ShoppingList> get lists => _lists;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get isGridView => _isGridView;
  ThemeMode get themeMode => _themeMode;
  int get selectedFilterIndex => _selectedFilterIndex;

  /// Returns filtered and sorted lists according to search query, active filter and pin status.
  List<ShoppingList> get filteredLists {
    return _lists.where((ShoppingList list) {
      // Filter tab check
      if (_selectedFilterIndex == 0) {
        if (list.isArchived) return false;
      } else if (_selectedFilterIndex == 1) {
        if (list.isArchived || list.pendingCount == 0) return false;
      } else if (_selectedFilterIndex == 2) {
        if (!list.isArchived) return false;
      }

      // Search query check
      if (_searchQuery.trim().isEmpty) return true;
      final String query = _searchQuery.toLowerCase();
      if (list.title.toLowerCase().contains(query)) return true;
      return list.items.any((ShoppingItem item) => item.name.toLowerCase().contains(query));
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // UI & PREFERENCES ACTIONS
  // ---------------------------------------------------------------------------

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void toggleThemeMode() {
    _themeMode = (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterIndex(int index) {
    _selectedFilterIndex = index;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CRUD & REPOSITORY OPERATIONS
  // ---------------------------------------------------------------------------

  Future<void> loadLists() async {
    _isLoading = true;
    notifyListeners();

    try {
      _lists = await repository.getAllLists(includeArchived: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ShoppingList> createList({
    required String title,
    int colorIndex = 0,
    List<ShoppingItem>? initialItems,
  }) async {
    final DateTime now = DateTime.now();
    final ShoppingList newList = ShoppingList(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Nueva Lista' : title.trim(),
      colorIndex: colorIndex,
      isPinned: false,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
      items: initialItems ?? <ShoppingItem>[],
    );

    await repository.saveList(newList);
    await loadLists();
    return newList;
  }

  Future<void> updateList(ShoppingList list) async {
    await repository.saveList(list.copyWith(updatedAt: DateTime.now()));
    await loadLists();
  }

  Future<void> deleteList(String id) async {
    await repository.deleteList(id);
    _lists.removeWhere((ShoppingList l) => l.id == id);
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    await repository.togglePinList(id);
    await loadLists();
  }

  Future<void> toggleArchive(String id, bool currentStatus) async {
    await repository.setArchived(id, !currentStatus);
    await loadLists();
  }

  Future<void> addItem(
    String listId,
    String name, {
    String? quantity,
    String? category,
  }) async {
    if (name.trim().isEmpty) return;

    final ShoppingItem newItem = ShoppingItem(
      id: _uuid.v4(),
      listId: listId,
      name: name.trim(),
      quantity: quantity?.trim().isNotEmpty == true ? quantity!.trim() : null,
      category: category?.trim().isNotEmpty == true ? category!.trim() : null,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    await repository.saveItem(newItem);
    await loadLists();
  }

  Future<void> toggleItem(String listId, String itemId, bool isCompleted) async {
    await repository.toggleItemCompleted(itemId, isCompleted);
    // Optimistic in-memory update for fluid instant feedback
    final int listIdx = _lists.indexWhere((ShoppingList l) => l.id == listId);
    if (listIdx != -1) {
      final List<ShoppingItem> updatedItems = _lists[listIdx].items.map((ShoppingItem item) {
        if (item.id == itemId) {
          return item.copyWith(isCompleted: isCompleted);
        }
        return item;
      }).toList();
      _lists[listIdx] = _lists[listIdx].copyWith(items: updatedItems, updatedAt: DateTime.now());
      notifyListeners();
    }
    // Refresh with persisted state
    await loadLists();
  }

  Future<void> deleteItem(String listId, String itemId) async {
    await repository.deleteItem(itemId);
    final int listIdx = _lists.indexWhere((ShoppingList l) => l.id == listId);
    if (listIdx != -1) {
      final List<ShoppingItem> updatedItems =
          _lists[listIdx].items.where((ShoppingItem item) => item.id != itemId).toList();
      _lists[listIdx] = _lists[listIdx].copyWith(items: updatedItems);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // INTEROPERABILITY (MARKDOWN & CSV)
  // ---------------------------------------------------------------------------

  String exportToMarkdown(ShoppingList list) {
    return repository.exportToMarkdown(list);
  }

  String exportToCsv(ShoppingList list) {
    return repository.exportToCsv(list);
  }

  Future<ShoppingList> importFromContent({
    required String filename,
    required String content,
  }) async {
    final ShoppingList parsedList = repository.importFromContent(
      filename: filename,
      content: content,
    );
    await repository.saveList(parsedList);
    await loadLists();
    return parsedList;
  }
}
