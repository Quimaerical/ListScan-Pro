import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../settings/data/repositories/settings_repository_impl.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../data/services/list_file_handler.dart';
import '../../domain/models/shopping_item.dart';
import '../../domain/models/shopping_list.dart';
import '../../domain/repositories/shopping_list_repository.dart';

/// Central state controller managing shopping lists, view modes, themes and search filters
/// using Flutter's native [ChangeNotifier] for ultra-responsive performance.
class ShoppingListsController extends ChangeNotifier {
  final ShoppingListRepository repository;
  final SettingsRepository settingsRepository;
  static const Uuid _uuid = Uuid();

  ShoppingListsController({
    required this.repository,
    SettingsRepository? settingsRepository,
  }) : settingsRepository = settingsRepository ?? InMemorySettingsRepository();

  List<ShoppingList> _lists = <ShoppingList>[];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _isGridView = false; // Default: structured vertical list
  ThemeMode _themeMode = ThemeMode.light;
  bool _isCompletedExpanded = true;
  int _selectedFilterIndex = 0; // 0: Todas, 1: Con pendientes, 2: Archivadas

  // Getters
  List<ShoppingList> get lists => _lists;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get isGridView => _isGridView;
  ThemeMode get themeMode => _themeMode;
  bool get isCompletedExpanded => _isCompletedExpanded;
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
      return list.items.any(
        (ShoppingItem item) => item.name.toLowerCase().contains(query),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // UI & PREFERENCES ACTIONS (persisted in SQLite via SettingsRepository)
  // ---------------------------------------------------------------------------

  /// Hydrates persisted preferences. Call once before `runApp` so the first
  /// frame already uses the saved theme (no light→dark flash).
  Future<void> loadSettings() async {
    try {
      final Map<String, String> values = await settingsRepository.loadAll();
      _themeMode = values[SettingsKeys.themeMode] == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
      _isGridView = values[SettingsKeys.isGridView] == '1';
      _isCompletedExpanded = values[SettingsKeys.completedExpanded] != '0';
      notifyListeners();
    } catch (e) {
      // Preferences are non-critical: keep defaults if storage is unavailable.
      debugPrint('ShoppingListsController.loadSettings failed: $e');
    }
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
    _persist(SettingsKeys.isGridView, _isGridView ? '1' : '0');
  }

  void toggleThemeMode() {
    _themeMode = (_themeMode == ThemeMode.light)
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
    _persist(
      SettingsKeys.themeMode,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  void toggleCompletedExpanded() {
    _isCompletedExpanded = !_isCompletedExpanded;
    notifyListeners();
    _persist(SettingsKeys.completedExpanded, _isCompletedExpanded ? '1' : '0');
  }

  /// Fire-and-forget write: the UI never waits on disk for a preference.
  void _persist(String key, String value) {
    settingsRepository.setValue(key, value).catchError((Object e) {
      debugPrint('ShoppingListsController._persist($key) failed: $e');
    });
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
    final String listId = _uuid.v4();

    int sortIdx = 0;
    final List<ShoppingItem> boundItems = (initialItems ?? <ShoppingItem>[])
        .map((ShoppingItem item) {
          return item.copyWith(
            listId: listId,
            sortOrder: item.sortOrder == 0 ? sortIdx++ : item.sortOrder,
          );
        })
        .toList();

    final ShoppingList newList = ShoppingList(
      id: listId,
      title: title.trim().isEmpty ? 'Nueva Lista' : title.trim(),
      colorIndex: colorIndex,
      isPinned: false,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
      items: boundItems,
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
    int amount = 1,
    double? price,
  }) async {
    if (name.trim().isEmpty) return;

    // A bare integer typed as "quantity" (e.g. "3") feeds the counter instead.
    String? detail = quantity?.trim().isNotEmpty == true
        ? quantity!.trim()
        : null;
    int resolvedAmount = amount;
    final int? parsed = detail != null ? int.tryParse(detail) : null;
    if (parsed != null && parsed > 0) {
      resolvedAmount = parsed;
      detail = null;
    }

    final ShoppingItem newItem = ShoppingItem(
      id: _uuid.v4(),
      listId: listId,
      name: name.trim(),
      quantity: detail,
      category: category?.trim().isNotEmpty == true ? category!.trim() : null,
      amount: ShoppingItem.clampAmount(resolvedAmount),
      price: price,
      isCompleted: false,
      sortOrder: _nextSortOrder(listId),
      createdAt: DateTime.now(),
    );

    await repository.saveItem(newItem);
    await loadLists();
  }

  /// Updates the unit price for an item with immediate optimistic UI update.
  Future<void> updateItemPrice(
    String listId,
    String itemId,
    double? price,
  ) async {
    final int listIdx = _lists.indexWhere((ShoppingList l) => l.id == listId);
    if (listIdx != -1) {
      final List<ShoppingItem> updatedItems = _lists[listIdx].items.map((
        ShoppingItem item,
      ) {
        if (item.id == itemId) {
          return item.copyWith(price: price, clearPrice: price == null);
        }
        return item;
      }).toList();
      _lists[listIdx] = _lists[listIdx].copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }

    await repository.updateItemPrice(itemId, price);
  }

  /// Imports multiple items and visual separators parsed from Markdown or multiline text directly into an existing list.
  Future<int> importMarkdownIntoList(String listId, String content) async {
    final int startSort = _nextSortOrder(listId);
    final List<ShoppingItem> parsedItems = ListFileHandler.parseMarkdownItems(
      content: content,
      listId: listId,
      startingSortOrder: startSort,
    );
    if (parsedItems.isEmpty) return 0;

    for (final ShoppingItem item in parsedItems) {
      await repository.saveItem(item);
    }
    await loadLists();
    return parsedItems.length;
  }

  /// Appends a visual separator (optionally labelled) at the end of the list.
  Future<void> addSeparator(String listId, {String? label}) async {
    final ShoppingItem separator = ShoppingItem(
      id: _uuid.v4(),
      listId: listId,
      name: label?.trim() ?? '',
      isSeparator: true,
      sortOrder: _nextSortOrder(listId),
      createdAt: DateTime.now(),
    );

    await repository.saveItem(separator);
    await loadLists();
  }

  /// Renames a separator (an empty label renders as a plain divider line).
  Future<void> renameSeparator(
    String listId,
    String itemId,
    String label,
  ) async {
    final ShoppingItem? current = _findItem(listId, itemId);
    if (current == null || !current.isSeparator) return;

    await repository.saveItem(current.copyWith(name: label.trim()));
    await loadLists();
  }

  /// Updates the integer counter with an optimistic in-memory update so the
  /// stepper feels instant; persistence happens in the background.
  Future<void> setItemAmount(String listId, String itemId, int amount) async {
    final int safeAmount = ShoppingItem.clampAmount(amount);
    final int listIdx = _lists.indexWhere((ShoppingList l) => l.id == listId);
    if (listIdx == -1) return;

    final List<ShoppingItem> updatedItems = _lists[listIdx].items.map((
      ShoppingItem item,
    ) {
      return item.id == itemId ? item.copyWith(amount: safeAmount) : item;
    }).toList();
    _lists[listIdx] = _lists[listIdx].copyWith(items: updatedItems);
    notifyListeners();

    await repository.updateItemAmount(itemId, safeAmount);
  }

  /// Queries SQLite for previously entered product names for autocomplete suggestions.
  Future<List<String>> getProductSuggestions(
    String query, {
    int limit = 8,
  }) async {
    return repository.getProductSuggestions(query, limit: limit);
  }

  int _nextSortOrder(String listId) {
    final int listIdx = _lists.indexWhere((ShoppingList l) => l.id == listId);
    if (listIdx == -1 || _lists[listIdx].items.isEmpty) return 0;
    return _lists[listIdx].items
            .map((ShoppingItem i) => i.sortOrder)
            .reduce((int a, int b) => a > b ? a : b) +
        1;
  }

  ShoppingItem? _findItem(String listId, String itemId) {
    final int listIdx = _lists.indexWhere((ShoppingList l) => l.id == listId);
    if (listIdx == -1) return null;
    for (final ShoppingItem item in _lists[listIdx].items) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  Future<void> toggleItem(
    String listId,
    String itemId,
    bool isCompleted,
  ) async {
    await repository.toggleItemCompleted(itemId, isCompleted);
    // Optimistic in-memory update for fluid instant feedback
    final int listIdx = _lists.indexWhere((ShoppingList l) => l.id == listId);
    if (listIdx != -1) {
      final List<ShoppingItem> updatedItems = _lists[listIdx].items.map((
        ShoppingItem item,
      ) {
        if (item.id == itemId) {
          return item.copyWith(isCompleted: isCompleted);
        }
        return item;
      }).toList();
      _lists[listIdx] = _lists[listIdx].copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
    // Refresh with persisted state
    await loadLists();
  }

  Future<void> deleteItem(String listId, String itemId) async {
    await repository.deleteItem(itemId);
    final int listIdx = _lists.indexWhere((ShoppingList l) => l.id == listId);
    if (listIdx != -1) {
      final List<ShoppingItem> updatedItems = _lists[listIdx].items
          .where((ShoppingItem item) => item.id != itemId)
          .toList();
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
