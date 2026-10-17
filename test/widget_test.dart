import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_item.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_list.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/controllers/shopping_lists_controller.dart';
import 'package:shopliist_pro/main.dart';

class MockShoppingListRepository implements ShoppingListRepository {
  final List<ShoppingList> _lists = [];

  @override
  Future<List<ShoppingList>> getAllLists({bool includeArchived = false}) async {
    return _lists;
  }

  @override
  Future<ShoppingList?> getListById(String id) async {
    return _lists.cast<ShoppingList?>().firstWhere((l) => l?.id == id, orElse: () => null);
  }

  @override
  Future<void> saveList(ShoppingList list) async {
    final idx = _lists.indexWhere((l) => l.id == list.id);
    if (idx != -1) {
      _lists[idx] = list;
    } else {
      _lists.add(list);
    }
  }

  @override
  Future<void> deleteList(String id) async {
    _lists.removeWhere((l) => l.id == id);
  }

  @override
  Future<void> togglePinList(String id) async {
    final idx = _lists.indexWhere((l) => l.id == id);
    if (idx != -1) {
      _lists[idx] = _lists[idx].copyWith(isPinned: !_lists[idx].isPinned);
    }
  }

  @override
  Future<void> setArchived(String id, bool isArchived) async {
    final idx = _lists.indexWhere((l) => l.id == id);
    if (idx != -1) {
      _lists[idx] = _lists[idx].copyWith(isArchived: isArchived);
    }
  }

  @override
  Future<void> saveItem(ShoppingItem item) async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<void> toggleItemCompleted(String id, bool isCompleted) async {}

  @override
  Future<void> updateItemAmount(String id, int amount) async {}

  @override
  Future<List<String>> getProductSuggestions(String query, {int limit = 10}) async => const [];

  @override
  String exportToMarkdown(ShoppingList list) => '# ${list.title}\n';

  @override
  String exportToCsv(ShoppingList list) => 'name,quantity,is_completed,category\n';

  @override
  ShoppingList importFromContent({required String filename, required String content}) {
    return ShoppingList(
      id: 'mock-1',
      title: 'Importada',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('Renders ListScan PRO Dashboard and empty state smoothly', (WidgetTester tester) async {
    final repository = MockShoppingListRepository();
    final controller = ShoppingListsController(repository: repository);

    await tester.pumpWidget(ListScanProApp(controller: controller));
    await tester.pumpAndSettle();

    // Verify Title & Brand
    expect(find.textContaining('List'), findsWidgets);
    expect(find.textContaining('Scan'), findsWidgets);
    expect(find.text('PRO'), findsOneWidget);

    // Verify Empty state greeting
    expect(find.text('¡Comienza tus listas de compras!'), findsOneWidget);
    expect(find.text('Crear mi primera lista'), findsOneWidget);

    // Verify Theme Switcher & View Switcher buttons
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

    // Tap theme toggle and verify smooth reactive switch
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });
}
