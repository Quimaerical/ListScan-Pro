import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/theme/app_colors.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/quick_add_bar.dart';

void main() {
  group('QuickAddBar Smart Link Detection', () {
    testWidgets('triggers onImportLink when entering a http or https URL', (
      WidgetTester tester,
    ) async {
      String? addedName;
      String? importedLink;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddBar(
              palette: AppColors.palettes[0],
              onAdd: (String name, String? qty) => addedName = name,
              onImportLink: (String url) => importedLink = url,
            ),
          ),
        ),
      );

      // Enter a normal item name
      await tester.enterText(
        find.byType(TextField).first,
        'Manzanas',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(addedName, equals('Manzanas'));
      expect(importedLink, isNull);

      // Reset
      addedName = null;

      // Enter a web URL
      await tester.enterText(
        find.byType(TextField).first,
        'https://recetas.com/arroz-con-pollo',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(importedLink, equals('https://recetas.com/arroz-con-pollo'));
      expect(addedName, isNull);
    });
  });
}
