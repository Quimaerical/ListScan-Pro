import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/theme/app_colors.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_item.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/shopping_item_tile.dart';

void main() {
  group('ShoppingItemTile Price Interaction', () {
    testWidgets('displays price chip and triggers onPriceChanged via dialog', (
      WidgetTester tester,
    ) async {
      final item = ShoppingItem(
        id: 'item-1',
        listId: 'list-1',
        name: 'Queso Gouda',
        amount: 2,
        price: 3.50,
        createdAt: DateTime.now(),
      );

      double? updatedPrice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShoppingItemTile(
              item: item,
              palette: AppColors.palettes[0],
              onToggleCompleted: (_) {},
              onPriceChanged: (double? p) => updatedPrice = p,
              onDelete: () {},
            ),
          ),
        ),
      );

      // Price chip should display 3.50
      expect(find.text('3.50'), findsOneWidget);

      // Tap price chip to open dialog
      await tester.tap(find.text('3.50'));
      await tester.pumpAndSettle();

      expect(find.text('Precio unitario de "Queso Gouda"'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter new price 4.75
      await tester.enterText(find.byType(TextField), '4.75');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(updatedPrice, equals(4.75));
    });
  });
}
