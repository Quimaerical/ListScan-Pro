import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/theme/app_colors.dart';
import 'package:shopliist_pro/features/shopping_lists/data/services/list_file_handler.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_item.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_list.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/controllers/shopping_lists_controller.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/quick_add_bar.dart';

class MockShoppingListRepository implements ShoppingListRepository {
  final Map<String, ShoppingList> _lists = <String, ShoppingList>{};

  MockShoppingListRepository([ShoppingList? initial]) {
    if (initial != null) {
      _lists[initial.id] = initial;
    }
  }

  @override
  Future<List<ShoppingList>> getAllLists({bool includeArchived = false}) async {
    return _lists.values.toList();
  }

  @override
  Future<ShoppingList?> getListById(String id) async {
    return _lists[id];
  }

  @override
  Future<void> saveList(ShoppingList list) async {
    _lists[list.id] = list;
  }

  @override
  Future<void> deleteList(String id) async {
    _lists.remove(id);
  }

  @override
  Future<void> togglePinList(String id) async {}

  @override
  Future<void> setArchived(String id, bool isArchived) async {}

  @override
  Future<void> saveItem(ShoppingItem item) async {
    final ShoppingList? list = _lists[item.listId];
    if (list != null) {
      final List<ShoppingItem> currentItems = List<ShoppingItem>.from(list.items);
      final int idx = currentItems.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        currentItems[idx] = item;
      } else {
        currentItems.add(item);
      }
      _lists[item.listId] = list.copyWith(items: currentItems);
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    for (final entry in _lists.entries) {
      final updated = entry.value.items.where((i) => i.id != id).toList();
      _lists[entry.key] = entry.value.copyWith(items: updated);
    }
  }

  @override
  Future<void> toggleItemCompleted(String id, bool isCompleted) async {}

  @override
  Future<void> updateItemAmount(String id, int amount) async {}

  @override
  Future<List<String>> getProductSuggestions(String query, {int limit = 10}) async => [];

  @override
  String exportToMarkdown(ShoppingList list) => ListFileHandler.exportToMarkdown(list);

  @override
  String exportToCsv(ShoppingList list) => ListFileHandler.exportToCsv(list);

  @override
  ShoppingList importFromContent({required String filename, required String content}) =>
      ListFileHandler.parseMarkdown(content: content);
}

void main() {
  group('ListFileHandler.parseMarkdownItems Tests', () {
    test('parses checklist, multipliers, and separators accurately', () {
      const markdown = '''
# Mi Lista Semanal

- [ ] 2x 1 kg Manzanas
--- Despensa ---
- [x] Leche entera
* [ ] 3x Latas de atun
---
- [ ] Pan de centeno
''';

      final items = ListFileHandler.parseMarkdownItems(
        content: markdown,
        listId: 'test-list-1',
      );

      expect(items.length, equals(6));

      // 1. Manzanas
      expect(items[0].name, equals('Manzanas'));
      expect(items[0].quantity, equals('1 kg'));
      expect(items[0].amount, equals(2));
      expect(items[0].isCompleted, isFalse);
      expect(items[0].isSeparator, isFalse);

      // 2. Separator Despensa
      expect(items[1].isSeparator, isTrue);
      expect(items[1].name, equals('Despensa'));

      // 3. Leche entera (completed)
      expect(items[2].name, equals('Leche entera'));
      expect(items[2].isCompleted, isTrue);

      // 4. Latas de atún
      expect(items[3].name, equals('Latas de atun'));
      expect(items[3].amount, equals(3));
      expect(items[3].isCompleted, isFalse);

      // 5. Plain separator
      expect(items[4].isSeparator, isTrue);
      expect(items[4].name, isEmpty);

      // 6. Pan de centeno
      expect(items[5].name, equals('Pan de centeno'));
      expect(items[5].isCompleted, isFalse);
    });

    test('parses plain multiline pasted text', () {
      const multiline = '''
Tomates
Cebollas
Pimientos verdes
''';

      final items = ListFileHandler.parseMarkdownItems(
        content: multiline,
        listId: 'test-list-2',
      );

      expect(items.length, equals(3));
      expect(items[0].name, equals('Tomates'));
      expect(items[1].name, equals('Cebollas'));
      expect(items[2].name, equals('Pimientos verdes'));
    });

    test('parses numbered lines', () {
      const numbered = '''
1. Huevos
2. Harina 1 kg
3) Azúcar
''';

      final items = ListFileHandler.parseMarkdownItems(
        content: numbered,
        listId: 'test-list-3',
      );

      expect(items.length, equals(3));
      expect(items[0].name, equals('Huevos'));
      expect(items[1].name, equals('Harina'));
      expect(items[1].quantity, equals('1 kg'));
      expect(items[2].name, equals('Azúcar'));
    });
  });

  group('ShoppingListsController.importMarkdownIntoList Tests', () {
    test('imports items and persists into active list', () async {
      final now = DateTime.now();
      final initialList = ShoppingList(
        id: 'list-123',
        title: 'Supermercado',
        colorIndex: 0,
        isPinned: false,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
        items: [],
      );

      final repo = MockShoppingListRepository(initialList);
      final controller = ShoppingListsController(repository: repo);
      await controller.loadLists();

      const pastedMarkdown = '''
- [ ] 2x Platanos
--- Congelados ---
- [x] Helado
''';

      final count = await controller.importMarkdownIntoList('list-123', pastedMarkdown);

      expect(count, equals(3));
      final updatedList = controller.lists.firstWhere((l) => l.id == 'list-123');
      expect(updatedList.items.length, equals(3));
      expect(updatedList.items[0].name, equals('Platanos'));
      expect(updatedList.items[0].amount, equals(2));
      expect(updatedList.items[1].isSeparator, isTrue);
      expect(updatedList.items[1].name, equals('Congelados'));
      expect(updatedList.items[2].name, equals('Helado'));
      expect(updatedList.items[2].isCompleted, isTrue);
    });
  });

  group('QuickAddBar Markdown Detection Widget Tests', () {
    testWidgets('triggers onImportMarkdown when multiline or markdown pasted', (WidgetTester tester) async {
      String? importedMarkdown;
      String? addedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddBar(
              palette: AppColors.palettes[0],
              onAdd: (name, qty) => addedName = name,
              onImportMarkdown: (md) => importedMarkdown = md,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, '- [ ] Manzanas\n- [ ] Peras');
      await tester.pump();

      await tester.tap(find.byTooltip('Guardar'));
      await tester.pump();

      expect(importedMarkdown, equals('- [ ] Manzanas\n- [ ] Peras'));
      expect(addedName, isNull);
    });

    testWidgets('triggers onAdd when single plain product entered', (WidgetTester tester) async {
      String? importedMarkdown;
      String? addedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddBar(
              palette: AppColors.palettes[0],
              onAdd: (name, qty) => addedName = name,
              onImportMarkdown: (md) => importedMarkdown = md,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Chocolate negro');
      await tester.pump();

      await tester.tap(find.byTooltip('Guardar'));
      await tester.pump();

      expect(addedName, equals('Chocolate negro'));
      expect(importedMarkdown, isNull);
    });
  });
}
