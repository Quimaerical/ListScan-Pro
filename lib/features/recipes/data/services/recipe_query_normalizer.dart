/// Intelligent query normalizer and bilingual culinary mapper that enables
/// natural searches in Spanish ("pollo", "arroz", "ramen", "ensalada")
/// while querying global and international recipe APIs seamlessly.
class RecipeQueryNormalizer {
  const RecipeQueryNormalizer._();

  static const Map<String, List<String>> _spanishToGlobalTerms = {
    'pollo': ['chicken', 'pollo'],
    'arroz': ['rice', 'arroz'],
    'ternera': ['beef', 'steak'],
    'carne': ['beef', 'meat', 'pork'],
    'cerdo': ['pork', 'cerdo'],
    'pescado': ['fish', 'salmon', 'tuna'],
    'salmon': ['salmon'],
    'atun': ['tuna'],
    'ensalada': ['salad'],
    'pasta': ['pasta', 'spaghetti'],
    'espagueti': ['spaghetti', 'pasta'],
    'fideos': ['noodles', 'ramen'],
    'fideo': ['noodles'],
    'sopa': ['soup'],
    'postre': ['dessert', 'cake'],
    'pastel': ['cake', 'pie'],
    'tarta': ['cake', 'tart'],
    'huevo': ['egg', 'eggs'],
    'huevos': ['egg', 'eggs'],
    'queso': ['cheese'],
    'patata': ['potato', 'potatoes'],
    'patatas': ['potato', 'potatoes'],
    'papa': ['potato'],
    'papas': ['potatoes'],
    'marisco': ['seafood', 'shrimp'],
    'mariscos': ['seafood', 'shrimp'],
    'gamba': ['prawn', 'shrimp'],
    'gambas': ['prawns', 'shrimp'],
    'camaron': ['shrimp'],
    'camarones': ['shrimp'],
    'vegetariano': ['vegetarian', 'vegetable'],
    'verduras': ['vegetable', 'vegetables'],
    'legumbres': ['lentil', 'beans'],
    'lentejas': ['lentil', 'soup'],
    'garbanzos': ['chickpea', 'hummus'],
    'albondigas': ['meatballs'],
    'hamburguesa': ['burger'],
    'pizza': ['pizza'],
    'pan': ['bread'],
    'tacos': ['taco', 'tacos'],

    // Asian gastronomy terms
    'ramen': ['ramen', 'noodle soup'],
    'sushi': ['sushi', 'roll'],
    'curry': ['curry', 'tikka'],
    'gyoza': ['dumpling', 'gyoza'],
    'gyozas': ['dumplings', 'gyoza'],
    'empanadillas': ['dumplings'],
    'arroz frito': ['fried rice'],
    'pad thai': ['pad thai', 'thai'],
    'teriyaki': ['teriyaki'],
    'tofu': ['tofu'],
    'bao': ['bao', 'bun'],
    'dumplings': ['dumplings'],
    'wok': ['stir fry', 'noodles'],
  };

  /// Returns relevant global search queries for a given user query.
  /// Always includes the original query as well.
  static List<String> expandQuery(String query) {
    final String clean = query.trim().toLowerCase();
    if (clean.isEmpty) return const [''];

    final List<String> results = <String>[clean];

    if (_spanishToGlobalTerms.containsKey(clean)) {
      for (final String term in _spanishToGlobalTerms[clean]!) {
        if (!results.contains(term)) {
          results.add(term);
        }
      }
    } else {
      // Check partial match in multi-word query
      for (final MapEntry<String, List<String>> entry
          in _spanishToGlobalTerms.entries) {
        if (clean.contains(entry.key)) {
          for (final String term in entry.value) {
            if (!results.contains(term)) {
              results.add(term);
            }
          }
        }
      }
    }

    return results;
  }
}
