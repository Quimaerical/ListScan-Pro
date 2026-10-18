import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/theme/app_colors.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/recipe_notes_card.dart';

void main() {
  group('RecipeNotesCard Widget Tests', () {
    testWidgets('renders empty state button and opens edit dialog', (
      WidgetTester tester,
    ) async {
      String? savedNotes;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeNotesCard(
              notes: null,
              palette: AppColors.palettes[0],
              onNotesChanged: (String? val) => savedNotes = val,
            ),
          ),
        ),
      );

      // Verify empty state is rendered
      expect(find.text('Añadir receta o notas...'), findsOneWidget);

      // Tap empty state button
      await tester.tap(find.text('Añadir receta o notas...'));
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.text('Receta y Notas'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter notes
      await tester.enterText(
        find.byType(TextField),
        '1. Precalentar horno a 200°C.\n2. Hornear por 30 min.',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(savedNotes, equals('1. Precalentar horno a 200°C.\n2. Hornear por 30 min.'));
    });

    testWidgets('renders populated state with preview, expands and edits', (
      WidgetTester tester,
    ) async {
      String? savedNotes = 'Nota existente de prueba';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return RecipeNotesCard(
                  notes: savedNotes,
                  palette: AppColors.palettes[0],
                  onNotesChanged: (String? val) {
                    setState(() => savedNotes = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify header and preview text
      expect(find.text('Receta y Notas'), findsOneWidget);
      expect(find.text('Nota existente de prueba'), findsAtLeastNWidgets(1));

      // Tap expand to toggle
      await tester.tap(find.text('Receta y Notas'));
      await tester.pumpAndSettle();

      // Tap edit button
      final editBtn = find.byTooltip('Editar notas');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Dialog shows current text
      expect(find.text('Receta y Notas'), findsNWidgets(2)); // Header in card + title in dialog
      expect(find.text('Borrar notas'), findsOneWidget);

      // Tap "Borrar notas"
      await tester.tap(find.text('Borrar notas'));
      await tester.pumpAndSettle();

      // Now savedNotes is null and empty state is rendered
      expect(find.text('Añadir receta o notas...'), findsOneWidget);
    });
  });
}
