import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shopliist_pro/features/recipes/data/services/web_recipe_extractor_service.dart';

void main() {
  group('WebRecipeExtractorService - parseIngredientLine', () {
    final service = WebRecipeExtractorService();

    test('parses grams with and without space', () {
      final ing1 = service.parseIngredientLine('500g de harina de trigo');
      expect(ing1.measure, '500g');
      expect(ing1.name, 'Harina de trigo');

      final ing2 = service.parseIngredientLine('250 gr azúcar blanco');
      expect(ing2.measure, '250 gr');
      expect(ing2.name, 'Azúcar blanco');
    });

    test('parses fractions and culinary cups/spoons', () {
      final ing1 = service.parseIngredientLine('1/2 taza de leche');
      expect(ing1.measure, '1/2 taza');
      expect(ing1.name, 'Leche');

      final ing2 = service.parseIngredientLine(
        '3 cucharadas de aceite de oliva',
      );
      expect(ing2.measure, '3 cucharadas');
      expect(ing2.name, 'Aceite de oliva');
    });

    test('parses units like cloves, pinches, and al gusto', () {
      final ing1 = service.parseIngredientLine('2 dientes de ajo picados');
      expect(ing1.measure, '2 dientes');
      expect(ing1.name, 'Ajo picados');

      final ing2 = service.parseIngredientLine('Sal y pimienta al gusto');
      expect(ing2.measure, 'al gusto');
      expect(ing2.name, 'Sal y pimienta');

      final ing3 = service.parseIngredientLine('1 pizca de nuez moscada');
      expect(ing3.measure, '1 pizca');
      expect(ing3.name, 'Nuez moscada');
    });

    test('strips leading bullets and numbers', () {
      final ing1 = service.parseIngredientLine('- 200 ml nata líquida');
      expect(ing1.measure, '200 ml');
      expect(ing1.name, 'Nata líquida');

      final ing2 = service.parseIngredientLine('1. 4 huevos grandes');
      expect(ing2.measure, '4');
      expect(ing2.name, 'Huevos grandes');
    });
  });

  group('WebRecipeExtractorService - parseFromRawText', () {
    final service = WebRecipeExtractorService();

    test('parses recipe text with ingredients and instructions sections', () {
      const rawText = '''
Ingredientes:
- 400g espaguetis
- 150g panceta o guanciale
- 3 huevos
- 50g queso pecorino
- Pimienta negra al gusto

Instrucciones:
1. Hervir los espaguetis al dente.
2. Dorar el guanciale en una sartén.
3. Mezclar los huevos con el queso rallado.
''';

      final recipe = service.parseFromRawText(
        title: 'Espaguetis Carbonara Tradicional',
        text: rawText,
      );

      expect(recipe.name, 'Espaguetis Carbonara Tradicional');
      expect(recipe.ingredients.length, 5);
      expect(recipe.ingredients[0].name, 'Espaguetis');
      expect(recipe.ingredients[0].measure, '400g');
      expect(recipe.ingredients[2].name, 'Huevos');
      expect(recipe.ingredients[2].measure, '3');
      expect(recipe.ingredients[4].measure, 'al gusto');
      expect(recipe.instructions, contains('Hervir los espaguetis al dente'));
    });
  });

  group('WebRecipeExtractorService - extractFromUrl', () {
    test('extracts recipe using Schema.org JSON-LD', () async {
      const sampleHtml = '''
<!DOCTYPE html>
<html>
<head>
  <title>Paella Valenciana - Recetas Tradicionales</title>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Recipe",
    "name": "Paella Valenciana Auténtica",
    "image": "https://example.com/paella.jpg",
    "recipeCuisine": "Española",
    "recipeCategory": "Plato Principal",
    "recipeIngredient": [
      "400 g arroz bomba",
      "500 g pollo troceado",
      "200 g judías verdes",
      "1 pizca de azafrán"
    ],
    "recipeInstructions": [
      {"@type": "HowToStep", "text": "Sofreír la carne en la paellera."},
      {"@type": "HowToStep", "text": "Añadir el arroz y el caldo caliente."}
    ]
  }
  </script>
</head>
<body><h1>Receta de Paella</h1></body>
</html>
''';

      final mockClient = MockClient((request) async {
        return http.Response(
          sampleHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      final service = WebRecipeExtractorService(httpClient: mockClient);
      final recipe = await service.extractFromUrl('https://recetas.es/paella');

      expect(recipe, isNotNull);
      expect(recipe!.name, 'Paella Valenciana Auténtica');
      expect(recipe.thumbnailUrl, 'https://example.com/paella.jpg');
      expect(recipe.area, 'Española');
      expect(recipe.ingredients.length, 4);
      expect(recipe.ingredients[0].name, 'Arroz bomba');
      expect(recipe.ingredients[0].measure, '400 g');
      expect(recipe.instructions, contains('Sofreír la carne'));
    });

    test('falls back to HTML lists when JSON-LD is absent', () async {
      const fallbackHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta property="og:title" content="Pollo al Limón Fácil">
  <meta property="og:image" content="https://example.com/pollo.jpg">
</head>
<body>
  <ul>
    <li class="recipe-ingredient">1 kg de pechuga de pollo</li>
    <li class="recipe-ingredient">2 limones exprimidos</li>
  </ul>
</body>
</html>
''';

      final mockClient = MockClient((request) async {
        return http.Response(
          fallbackHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      final service = WebRecipeExtractorService(httpClient: mockClient);
      final recipe = await service.extractFromUrl(
        'https://blogs.com/pollo-limon',
      );

      expect(recipe, isNotNull);
      expect(recipe!.name, 'Pollo al Limón Fácil');
      expect(recipe.thumbnailUrl, 'https://example.com/pollo.jpg');
      expect(recipe.ingredients.length, 2);
      expect(recipe.ingredients[0].name, 'Pechuga de pollo');
      expect(recipe.ingredients[0].measure, '1 kg');
    });
  });
}
