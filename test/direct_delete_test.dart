import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/theme/app_colors.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_item.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_list.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/note_card_widget.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/shopping_item_tile.dart';

void main() {
  group('Direct Deletion Actions', () {
    testWidgets('ShoppingItemTile direct delete button triggers onDelete', (
      WidgetTester tester,
    ) async {
      final item = ShoppingItem(
        id: 'item-1',
        listId: 'list-1',
        name: 'Queso Gouda',
        createdAt: DateTime.now(),
      );

      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShoppingItemTile(
              item: item,
              palette: AppColors.palettes[0],
              onToggleCompleted: (_) {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      final deleteBtn = find.byTooltip('Eliminar producto');
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pump();

      expect(deleted, isTrue);
    });

    testWidgets('NoteCardWidget direct delete button shows confirmation dialog and deletes', (
      WidgetTester tester,
    ) async {
      final list = ShoppingList(
        id: 'list-1',
        title: 'Supermercado',
        colorIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteCardWidget(
              list: list,
              isGrid: false,
              onTap: () {},
              onTogglePin: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      final deleteBtn = find.byTooltip('Eliminar lista');
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar lista?'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
