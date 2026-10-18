import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/features/shopping_lists/data/services/list_file_handler.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_item.dart';
import 'package:shopliist_pro/features/shopping_lists/domain/models/shopping_list.dart';

void main() {
  group('ListFileHandler - Markdown (.md)', () {
    test('exports ShoppingList to Markdown with checklist syntax', () {
      final now = DateTime.now();
      final list = ShoppingList(
        id: 'test-1',
        title: 'Supermercado Fin de Semana',
        createdAt: now,
        updatedAt: now,
        items: [
          ShoppingItem(
            id: 'item-1',
            listId: 'test-1',
            name: 'Manzanas',
            quantity: '2 kg',
            isCompleted: false,
            createdAt: now,
          ),
          ShoppingItem(
            id: 'item-2',
            listId: 'test-1',
            name: 'Leche entera',
            quantity: '1 L',
            isCompleted: true,
            createdAt: now,
          ),
          ShoppingItem(
            id: 'item-3',
            listId: 'test-1',
            name: 'Pan',
            isCompleted: false,
            createdAt: now,
          ),
        ],
      );

      final markdown = ListFileHandler.exportToMarkdown(list);

      expect(markdown, contains('# Supermercado Fin de Semana'));
      expect(markdown, contains('- [ ] 2 kg Manzanas'));
      expect(markdown, contains('- [x] 1 L Leche entera'));
      expect(markdown, contains('- [ ] Pan'));
    });

    test('parses Markdown content with checklist into ShoppingList', () {
      const markdown = '''
# Asado Domingo

- [ ] 3 kg Carne para asar
- [x] Carbón vegetal
* [ ] 6 botellas Cerveza
''';

      final parsed = ListFileHandler.parseMarkdown(content: markdown);

      expect(parsed.title, equals('Asado Domingo'));
      expect(parsed.items.length, equals(3));

      expect(parsed.items[0].name, equals('Carne para asar'));
      expect(parsed.items[0].quantity, equals('3 kg'));
      expect(parsed.items[0].isCompleted, isFalse);

      expect(parsed.items[1].name, equals('Carbón vegetal'));
      expect(parsed.items[1].quantity, isNull);
      expect(parsed.items[1].isCompleted, isTrue);

      expect(parsed.items[2].name, equals('Cerveza'));
      expect(parsed.items[2].quantity, equals('6 botellas'));
      expect(parsed.items[2].isCompleted, isFalse);
    });
  });

  group('ListFileHandler - CSV (RFC 4180)', () {
    test('exports ShoppingList with price and total estimated line', () {
      final now = DateTime.now();
      final list = ShoppingList(
        id: 'test-price',
        title: 'Mercado Semanal',
        createdAt: now,
        updatedAt: now,
        items: [
          ShoppingItem(
            id: 'item-1',
            listId: 'test-price',
            name: 'Café',
            amount: 2,
            price: 3.50,
            createdAt: now,
          ),
          ShoppingItem(
            id: 'item-2',
            listId: 'test-price',
            name: 'Pan',
            amount: 1,
            price: 1.50,
            createdAt: now,
          ),
        ],
      );

      final markdown = ListFileHandler.exportToMarkdown(list);
      expect(markdown, contains('- [ ] 2x Café (\$3.50)'));
      expect(markdown, contains('- [ ] Pan (\$1.50)'));
      expect(markdown, contains('**Total estimado: \$8.50**'));
    });

    test('parses Markdown content with price suffix', () {
      const markdown = '''
# Compras
- [ ] 2x Café (\$3.50)
- [x] Pan (\$1.50)
- [ ] Manzanas
''';

      final parsed = ListFileHandler.parseMarkdown(content: markdown);
      expect(parsed.items.length, equals(3));
      expect(parsed.items[0].name, equals('Café'));
      expect(parsed.items[0].amount, equals(2));
      expect(parsed.items[0].price, equals(3.50));

      expect(parsed.items[1].name, equals('Pan'));
      expect(parsed.items[1].amount, equals(1));
      expect(parsed.items[1].price, equals(1.50));

      expect(parsed.items[2].name, equals('Manzanas'));
      expect(parsed.items[2].price, isNull);
    });

    test('exports ShoppingList to CSV RFC 4180 format with price and amount', () {
      final now = DateTime.now();
      final list = ShoppingList(
        id: 'test-2',
        title: 'Ferretería',
        createdAt: now,
        updatedAt: now,
        items: [
          ShoppingItem(
            id: 'item-4',
            listId: 'test-2',
            name: 'Tornillos, arandelas',
            quantity: '50 uds',
            category: 'Herramientas',
            amount: 2,
            price: 4.25,
            isCompleted: false,
            createdAt: now,
          ),
          ShoppingItem(
            id: 'item-5',
            listId: 'test-2',
            name: 'Cinta aislante',
            isCompleted: true,
            createdAt: now,
          ),
        ],
      );

      final csv = ListFileHandler.exportToCsv(list);

      expect(csv, contains('name,quantity,is_completed,category,amount,price'));
      expect(csv, contains('"Tornillos, arandelas",50 uds,0,Herramientas,2,4.25'));
      expect(csv, contains('Cinta aislante,,1,,1,'));
    });

    test('parses CSV content with RFC 4180 into ShoppingList', () {
      const csv = '''name,quantity,is_completed,category,amount,price
"Manzanas, peras y uvas",2 kg,0,Frutas,1,5.50
Leche deslactosada,1 L,1,Lácteos,2,1.25
Pan campesino,,0,Panadería,1,
''';

      final parsed = ListFileHandler.parseCsv(
        content: csv,
        defaultTitle: 'Compras Importadas',
      );

      expect(parsed.title, equals('Compras Importadas'));
      expect(parsed.items.length, equals(3));

      expect(parsed.items[0].name, equals('Manzanas, peras y uvas'));
      expect(parsed.items[0].quantity, equals('2 kg'));
      expect(parsed.items[0].isCompleted, isFalse);
      expect(parsed.items[0].category, equals('Frutas'));
      expect(parsed.items[0].amount, equals(1));
      expect(parsed.items[0].price, equals(5.50));

      expect(parsed.items[1].name, equals('Leche deslactosada'));
      expect(parsed.items[1].quantity, equals('1 L'));
      expect(parsed.items[1].isCompleted, isTrue);
      expect(parsed.items[1].amount, equals(2));
      expect(parsed.items[1].price, equals(1.25));

      expect(parsed.items[2].name, equals('Pan campesino'));
      expect(parsed.items[2].quantity, isNull);
      expect(parsed.items[2].isCompleted, isFalse);
      expect(parsed.items[2].amount, equals(1));
      expect(parsed.items[2].price, isNull);
    });
  });
}
