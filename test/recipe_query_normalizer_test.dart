import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/features/recipes/data/services/recipe_query_normalizer.dart';

void main() {
  group('RecipeQueryNormalizer', () {
    test(
      'expands Spanish culinary terms to include English/global keywords',
      () {
        final queries = RecipeQueryNormalizer.expandQuery('pollo');
        expect(queries, contains('pollo'));
        expect(queries, contains('chicken'));
      },
    );

    test('expands Asian gastronomy terms', () {
      final ramenQueries = RecipeQueryNormalizer.expandQuery('ramen');
      expect(ramenQueries, contains('ramen'));
      expect(ramenQueries, contains('noodle soup'));

      final gyozaQueries = RecipeQueryNormalizer.expandQuery('gyoza');
      expect(gyozaQueries, contains('gyoza'));
      expect(gyozaQueries, contains('dumpling'));
    });

    test('handles partial matching in multi-word Spanish queries', () {
      final queries = RecipeQueryNormalizer.expandQuery('arroz con pollo');
      expect(queries, contains('arroz con pollo'));
      expect(queries, contains('chicken'));
      expect(queries, contains('rice'));
    });

    test('returns original query if no mapping exists', () {
      final queries = RecipeQueryNormalizer.expandQuery('smoothie');
      expect(queries, ['smoothie']);
    });

    test('handles empty input gracefully', () {
      final queries = RecipeQueryNormalizer.expandQuery('');
      expect(queries, ['']);
    });
  });
}
