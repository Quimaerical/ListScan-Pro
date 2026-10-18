import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_item.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_list.dart';

void main() {
  group('ShoppingItem Model', () {
    test('serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime.parse('2026-10-16T18:00:00.000Z');
      final item = ShoppingItem(
        id: 'item-100',
        listId: 'list-200',
        name: 'Aguacates',
        quantity: '4 unidades',
        category: 'Verduras',
        isCompleted: true,
        sortOrder: 2,
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['id'], equals('item-100'));
      expect(map['list_id'], equals('list-200'));
      expect(map['name'], equals('Aguacates'));
      expect(map['quantity'], equals('4 unidades'));
      expect(map['category'], equals('Verduras'));
      expect(map['is_completed'], equals(1));
      expect(map['sort_order'], equals(2));
      expect(map['price'], isNull);

      final restored = ShoppingItem.fromMap(map);
      expect(restored.id, equals(item.id));
      expect(restored.listId, equals(item.listId));
      expect(restored.name, equals(item.name));
      expect(restored.quantity, equals(item.quantity));
      expect(restored.category, equals(item.category));
      expect(restored.isCompleted, equals(item.isCompleted));
      expect(restored.sortOrder, equals(item.sortOrder));
      expect(restored.price, isNull);
      expect(restored.totalLinePrice, isNull);
    });

    test('serializes and calculates price and totalLinePrice properly', () {
      final now = DateTime.now();
      final item = ShoppingItem(
        id: '1',
        listId: '10',
        name: 'Café',
        amount: 3,
        price: 4.50,
        createdAt: now,
      );

      expect(item.price, equals(4.50));
      expect(item.totalLinePrice, equals(13.50));

      final map = item.toMap();
      expect(map['price'], equals(4.50));

      final restored = ShoppingItem.fromMap(map);
      expect(restored.price, equals(4.50));
      expect(restored.totalLinePrice, equals(13.50));
    });

    test('copyWith updates properties properly', () {
      final now = DateTime.now();
      final item = ShoppingItem(
        id: '1',
        listId: '10',
        name: 'Arroz',
        createdAt: now,
      );

      final updated = item.copyWith(
        isCompleted: true,
        quantity: '1 kg',
        price: 2.50,
      );
      expect(updated.id, equals('1'));
      expect(updated.name, equals('Arroz'));
      expect(updated.isCompleted, isTrue);
      expect(updated.quantity, equals('1 kg'));
      expect(updated.price, equals(2.50));

      final clearedPrice = updated.copyWith(clearPrice: true);
      expect(clearedPrice.price, isNull);
    });
  });

  group('ShoppingList Model', () {
    test('computes counters and progressPercentage accurately', () {
      final now = DateTime.now();
      final list = ShoppingList(
        id: 'list-1',
        title: 'Cena Especial',
        createdAt: now,
        updatedAt: now,
        items: [
          ShoppingItem(
            id: '1',
            listId: 'list-1',
            name: 'Pasta',
            isCompleted: true,
            createdAt: now,
          ),
          ShoppingItem(
            id: '2',
            listId: 'list-1',
            name: 'Salsa',
            isCompleted: true,
            createdAt: now,
          ),
          ShoppingItem(
            id: '3',
            listId: 'list-1',
            name: 'Queso',
            isCompleted: false,
            createdAt: now,
          ),
          ShoppingItem(
            id: '4',
            listId: 'list-1',
            name: 'Vino',
            isCompleted: false,
            createdAt: now,
          ),
        ],
      );

      expect(list.totalCount, equals(4));
      expect(list.completedCount, equals(2));
      expect(list.pendingCount, equals(2));
      expect(list.progressPercentage, equals(0.5));
    });

    test('handles empty items without division by zero', () {
      final now = DateTime.now();
      final emptyList = ShoppingList(
        id: 'empty',
        title: 'Vacía',
        createdAt: now,
        updatedAt: now,
      );

      expect(emptyList.totalCount, equals(0));
      expect(emptyList.completedCount, equals(0));
      expect(emptyList.pendingCount, equals(0));
      expect(emptyList.progressPercentage, equals(0.0));
    });

    test('ignores visual separators in totalCount and completedCount', () {
      final now = DateTime.now();
      final listWithSeparators = ShoppingList(
        id: 'sep-list',
        title: 'Con Separadores',
        createdAt: now,
        updatedAt: now,
        items: [
          ShoppingItem(
            id: 's1',
            listId: 'sep-list',
            name: 'Frutas',
            isSeparator: true,
            createdAt: now,
          ),
          ShoppingItem(
            id: 'p1',
            listId: 'sep-list',
            name: 'Manzanas',
            isCompleted: true,
            amount: 3,
            createdAt: now,
          ),
          ShoppingItem(
            id: 's2',
            listId: 'sep-list',
            name: 'Bebidas',
            isSeparator: true,
            createdAt: now,
          ),
          ShoppingItem(
            id: 'p2',
            listId: 'sep-list',
            name: 'Agua',
            isCompleted: false,
            amount: 2,
            createdAt: now,
          ),
        ],
      );

      // Only real products count: p1 and p2 (total: 2, completed: 1)
      expect(listWithSeparators.totalCount, equals(2));
      expect(listWithSeparators.completedCount, equals(1));
      expect(listWithSeparators.pendingCount, equals(1));
      expect(listWithSeparators.progressPercentage, equals(0.5));
    });

    test('calculates totalPrice and hasPrices accurately', () {
      final now = DateTime.now();
      final list = ShoppingList(
        id: 'price-list',
        title: 'Supermercado',
        createdAt: now,
        updatedAt: now,
        items: [
          ShoppingItem(
            id: '1',
            listId: 'price-list',
            name: 'Leche',
            amount: 2,
            price: 1.50, // 2 * 1.50 = 3.00
            createdAt: now,
          ),
          ShoppingItem(
            id: 'sep',
            listId: 'price-list',
            name: 'Panadería',
            isSeparator: true,
            createdAt: now,
          ),
          ShoppingItem(
            id: '2',
            listId: 'price-list',
            name: 'Pan',
            amount: 1,
            price: 2.25, // 1 * 2.25 = 2.25
            createdAt: now,
          ),
          ShoppingItem(
            id: '3',
            listId: 'price-list',
            name: 'Huevos',
            amount: 1,
            // price is null -> ignored in total
            createdAt: now,
          ),
        ],
      );

      expect(list.hasPrices, isTrue);
      expect(list.totalPrice, equals(5.25));

      final noPriceList = ShoppingList(
        id: 'no-price',
        title: 'Sin precios',
        createdAt: now,
        updatedAt: now,
        items: [
          ShoppingItem(
            id: '1',
            listId: 'no-price',
            name: 'Agua',
            createdAt: now,
          ),
        ],
      );
      expect(noPriceList.hasPrices, isFalse);
      expect(noPriceList.totalPrice, equals(0.0));
    });

    test('serializes and deserializes notes properly, and updates via copyWith', () {
      final now = DateTime.now();
      final listWithNotes = ShoppingList(
        id: 'notes-list',
        title: 'Tacos al Pastor',
        notes: '1. Marinar la carne con achiote y naranja.\n2. Asar con piña.',
        createdAt: now,
        updatedAt: now,
      );

      expect(listWithNotes.hasNotes, isTrue);
      expect(listWithNotes.notes, contains('Marinar la carne'));

      final map = listWithNotes.toMap();
      expect(map['notes'], equals(listWithNotes.notes));

      final fromMap = ShoppingList.fromMap(map);
      expect(fromMap.notes, equals(listWithNotes.notes));
      expect(fromMap.hasNotes, isTrue);

      final clearedNotes = listWithNotes.copyWith(clearNotes: true);
      expect(clearedNotes.notes, isNull);
      expect(clearedNotes.hasNotes, isFalse);

      final listWithoutNotes = ShoppingList(
        id: 'no-notes',
        title: 'Simple',
        createdAt: now,
        updatedAt: now,
      );
      expect(listWithoutNotes.hasNotes, isFalse);
      expect(listWithoutNotes.notes, isNull);
    });
  });
}
