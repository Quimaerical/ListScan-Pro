import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/recipe.dart';
import '../../domain/models/recipe_ingredient.dart';

/// Service responsible for extracting structured culinary recipes and ingredient
/// lists from any webpage URL (prioritizing Schema.org Recipe JSON-LD, falling back
/// to OpenGraph / HTML lists) or from arbitrary pasted raw text / OCR recognition results.
class WebRecipeExtractorService {
  final http.Client _httpClient;

  WebRecipeExtractorService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const String _browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 ListScanPRO/1.0';

  static const String _unitsPattern =
      r'(?:gramos|gramo|gr|g|kilogramos|kilos|kilo|kg|mililitros|ml|litros|litro|l|'
      r'cucharadas|cucharada|cdas|cda|tbsp|cucharaditas|cucharadita|cdtas|cdta|tsp|'
      r'tazas|taza|cups|cup|oz|onzas|onza|lb|libras|libra|dientes|diente|cloves|clove|'
      r'pizca|pizcas|pinch|rebanadas|rebanada|slices|slice|rodajas|rodaja|'
      r'piezas|pieza|unidades|unidad|uds|ud|latas|lata|bote|botes|paquete|paquetes)';

  static final RegExp _measurePrefixRegex = RegExp(
    r'^((?:\d+(?:[\.,/]\d+)?(?:\s*-\s*\d+(?:[\.,/]\d+)?)?)\s*' +
        _unitsPattern +
        r'?|una?\s+' +
        _unitsPattern +
        r')\s*(?:de\s+)?(.*)$',
    caseSensitive: false,
  );

  /// Extracts recipe details from a website URL.
  Future<Recipe?> extractFromUrl(String urlString) async {
    final String cleanUrl = urlString.trim();
    if (cleanUrl.isEmpty) return null;

    final Uri? uri = Uri.tryParse(cleanUrl);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return null;
    }

    try {
      final http.Response response = await _httpClient
          .get(
            uri,
            headers: <String, String>{
              'User-Agent': _browserUserAgent,
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return null;
      }

      String body;
      try {
        body = utf8.decode(response.bodyBytes);
      } catch (_) {
        body = response.body;
      }

      // 1. Primary Strategy: Schema.org JSON-LD
      final Recipe? jsonLdRecipe = _extractFromJsonLd(body, cleanUrl);
      if (jsonLdRecipe != null && jsonLdRecipe.ingredients.isNotEmpty) {
        return jsonLdRecipe;
      }

      // 2. Secondary Strategy: OpenGraph meta tags + HTML list parsing
      final Recipe? htmlRecipe = _extractFromHtmlFallback(body, cleanUrl);
      if (htmlRecipe != null && htmlRecipe.ingredients.isNotEmpty) {
        return htmlRecipe;
      }

      return jsonLdRecipe ?? htmlRecipe;
    } catch (_) {
      return null;
    }
  }

  /// Parses a multi-line raw text (from clipboard, paste, or camera OCR text recognition).
  Recipe parseFromRawText({
    required String title,
    required String text,
    String? sourceUrl,
    String? imageUrl,
  }) {
    final List<String> lines = text.split(RegExp(r'\r?\n'));
    final List<RecipeIngredient> ingredients = <RecipeIngredient>[];
    final StringBuffer instructions = StringBuffer();
    bool isInInstructions = false;

    for (final String rawLine in lines) {
      final String line = rawLine.trim();
      if (line.isEmpty) continue;

      final String lower = line.toLowerCase();

      // Detect transition to instructions section
      if (lower.contains('instrucciones') ||
          lower.contains('preparación') ||
          lower.contains('elaboración') ||
          lower.contains('paso a paso') ||
          lower.contains('directions') ||
          lower.contains('instructions')) {
        isInInstructions = true;
        continue;
      }

      // Skip ingredients section header
      if (lower.startsWith('ingrediente') || lower.startsWith('ingredients')) {
        isInInstructions = false;
        continue;
      }

      if (isInInstructions) {
        instructions.writeln(line);
      } else {
        final RecipeIngredient ing = parseIngredientLine(line);
        if (ing.name.isNotEmpty) {
          ingredients.add(ing);
        }
      }
    }

    final String cleanTitle = title.trim().isNotEmpty
        ? _formatTitle(title.trim())
        : 'Receta Personalizada';

    return Recipe(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanTitle,
      category: 'Receta Importada',
      area: sourceUrl != null && sourceUrl.isNotEmpty ? 'Web' : 'Texto / OCR',
      instructions: instructions.isNotEmpty
          ? instructions.toString().trim()
          : null,
      thumbnailUrl: imageUrl,
      ingredients: ingredients,
    );
  }

  /// Parses a single ingredient line into quantity/measure and ingredient name.
  RecipeIngredient parseIngredientLine(String rawLine) {
    String s = rawLine.trim();

    // Remove leading list bullets and numbers like "- ", "* ", "• ", "1. ", "1) ", "[ ] "
    s = s.replaceFirst(RegExp(r'^[\s\-*•–—>#]+'), '').trim();
    s = s.replaceFirst(RegExp(r'^\s*\[\s*\]\s*'), '').trim();
    s = s.replaceFirst(RegExp(r'^\d+[\.\)]\s+'), '').trim();

    if (s.isEmpty) {
      return const RecipeIngredient(name: '', measure: '');
    }

    // Match "al gusto" at the end (e.g. "Sal y pimienta al gusto")
    final RegExp alGustoRegex = RegExp(
      r'\s+al\s+gusto.*$',
      caseSensitive: false,
    );
    if (alGustoRegex.hasMatch(s)) {
      final String name = s.replaceFirst(alGustoRegex, '').trim();
      return RecipeIngredient(
        name: _formatIngredientName(name),
        measure: 'al gusto',
        isSelected: true,
      );
    }

    final Match? match = _measurePrefixRegex.firstMatch(s);
    if (match != null) {
      final String measure = (match.group(1) ?? '').trim();
      final String name = (match.group(2) ?? '').trim();

      if (name.isNotEmpty) {
        return RecipeIngredient(
          name: _formatIngredientName(name),
          measure: measure,
          isSelected: true,
        );
      }
    }

    return RecipeIngredient(
      name: _formatIngredientName(s),
      measure: '',
      isSelected: true,
    );
  }

  Recipe? _extractFromJsonLd(String html, String sourceUrl) {
    final RegExp scriptRegex = RegExp(
      r'''<script[^>]*type=["']application\/ld\+json["'][^>]*>(.*?)<\/script>''',
      caseSensitive: false,
      dotAll: true,
    );

    final Iterable<Match> matches = scriptRegex.allMatches(html);

    for (final Match match in matches) {
      final String? jsonString = match.group(1);
      if (jsonString == null || jsonString.trim().isEmpty) continue;

      try {
        final dynamic decoded = jsonDecode(jsonString.trim());
        final Map<String, dynamic>? recipeMap = _findRecipeObject(decoded);

        if (recipeMap != null) {
          return _buildRecipeFromJsonLdMap(recipeMap, sourceUrl);
        }
      } catch (_) {
        // Continue searching in subsequent JSON-LD blocks
      }
    }

    return null;
  }

  Map<String, dynamic>? _findRecipeObject(dynamic json) {
    if (json is Map<String, dynamic>) {
      final dynamic type = json['@type'];
      if (_isRecipeType(type)) {
        return json;
      }

      final dynamic graph = json['@graph'];
      if (graph is List) {
        for (final dynamic item in graph) {
          if (item is Map<String, dynamic> && _isRecipeType(item['@type'])) {
            return item;
          }
        }
      }
    } else if (json is List) {
      for (final dynamic item in json) {
        if (item is Map<String, dynamic> && _isRecipeType(item['@type'])) {
          return item;
        }
      }
    }
    return null;
  }

  bool _isRecipeType(dynamic type) {
    if (type == null) return false;
    if (type is String) {
      return type.toLowerCase() == 'recipe';
    }
    if (type is List) {
      return type.any((dynamic t) => t.toString().toLowerCase() == 'recipe');
    }
    return false;
  }

  Recipe _buildRecipeFromJsonLdMap(Map<String, dynamic> map, String sourceUrl) {
    final String rawName = map['name']?.toString() ?? 'Receta Web';
    final String name = _cleanHtmlEntities(rawName).trim();

    // Extract image
    String? imageUrl;
    final dynamic rawImage = map['image'];
    if (rawImage is String && rawImage.isNotEmpty) {
      imageUrl = rawImage;
    } else if (rawImage is List && rawImage.isNotEmpty) {
      final dynamic first = rawImage.first;
      if (first is String) {
        imageUrl = first;
      } else if (first is Map && first['url'] != null) {
        imageUrl = first['url'].toString();
      }
    } else if (rawImage is Map && rawImage['url'] != null) {
      imageUrl = rawImage['url'].toString();
    }

    // Extract category & cuisine
    final String? category = map['recipeCategory']?.toString();
    final String? cuisine = map['recipeCuisine']?.toString();

    // Extract ingredients
    final List<RecipeIngredient> ingredients = <RecipeIngredient>[];
    final dynamic rawIngredients = map['recipeIngredient'];
    if (rawIngredients is List) {
      for (final dynamic item in rawIngredients) {
        if (item != null) {
          final String cleanLine = _cleanHtmlEntities(item.toString());
          final RecipeIngredient parsed = parseIngredientLine(cleanLine);
          if (parsed.name.isNotEmpty) {
            ingredients.add(parsed);
          }
        }
      }
    }

    // Extract instructions
    final StringBuffer instructions = StringBuffer();
    final dynamic rawInstructions = map['recipeInstructions'];
    if (rawInstructions is String) {
      instructions.write(_cleanHtmlEntities(rawInstructions));
    } else if (rawInstructions is List) {
      for (int i = 0; i < rawInstructions.length; i++) {
        final dynamic step = rawInstructions[i];
        if (step is String) {
          instructions.writeln('${i + 1}. ${_cleanHtmlEntities(step)}');
        } else if (step is Map) {
          final dynamic text = step['text'] ?? step['name'];
          if (text != null) {
            instructions.writeln(
              '${i + 1}. ${_cleanHtmlEntities(text.toString())}',
            );
          }
        }
      }
    }

    return Recipe(
      id: 'web_${DateTime.now().millisecondsSinceEpoch}',
      name: name.isNotEmpty ? name : 'Receta Web',
      category: category ?? 'Web / Blog',
      area: cuisine ?? 'Cocina Internacional',
      instructions: instructions.isNotEmpty
          ? instructions.toString().trim()
          : null,
      thumbnailUrl: imageUrl,
      ingredients: ingredients,
    );
  }

  Recipe? _extractFromHtmlFallback(String html, String sourceUrl) {
    // 1. Title from og:title or <title>
    String title = '';
    final RegExp ogTitle = RegExp(
      r'''<meta[^>]*property=["']og:title["'][^>]*content=["']([^"']+)["']''',
      caseSensitive: false,
    );
    final Match? ogMatch = ogTitle.firstMatch(html);
    if (ogMatch != null) {
      title = ogMatch.group(1) ?? '';
    } else {
      final RegExp titleTag = RegExp(
        r'<title[^>]*>([^<]+)</title>',
        caseSensitive: false,
      );
      final Match? tMatch = titleTag.firstMatch(html);
      if (tMatch != null) {
        title = tMatch.group(1) ?? '';
      }
    }

    title = _cleanHtmlEntities(title).split('|').first.split('-').first.trim();
    if (title.isEmpty) title = 'Receta Web';

    // 2. Image from og:image
    String? imageUrl;
    final RegExp ogImage = RegExp(
      r'''<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']''',
      caseSensitive: false,
    );
    final Match? imgMatch = ogImage.firstMatch(html);
    if (imgMatch != null) {
      imageUrl = imgMatch.group(1);
    }

    // 3. Extract ingredient list items from HTML
    final List<RecipeIngredient> ingredients = <RecipeIngredient>[];
    final RegExp liRegex = RegExp(
      r'''<li[^>]*class=["'][^"']*ingredient[^"']*["'][^>]*>(.*?)</li>''',
      caseSensitive: false,
      dotAll: true,
    );

    final Iterable<Match> liMatches = liRegex.allMatches(html);
    for (final Match m in liMatches) {
      final String rawText = m.group(1) ?? '';
      // Strip inner html tags
      final String stripped = rawText.replaceAll(RegExp(r'<[^>]*>'), ' ');
      final String cleaned = _cleanHtmlEntities(stripped).trim();
      if (cleaned.isNotEmpty) {
        final RecipeIngredient ing = parseIngredientLine(cleaned);
        if (ing.name.isNotEmpty) {
          ingredients.add(ing);
        }
      }
    }

    if (ingredients.isEmpty) {
      return null;
    }

    return Recipe(
      id: 'web_html_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      category: 'Web',
      area: 'Receta Web',
      thumbnailUrl: imageUrl,
      ingredients: ingredients,
    );
  }

  static String _cleanHtmlEntities(String text) {
    return text
        .replaceAll('&aacute;', 'á')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&iacute;', 'í')
        .replaceAll('&oacute;', 'ó')
        .replaceAll('&uacute;', 'ú')
        .replaceAll('&ntilde;', 'ñ')
        .replaceAll('&Aacute;', 'Á')
        .replaceAll('&Eacute;', 'É')
        .replaceAll('&Iacute;', 'Í')
        .replaceAll('&Oacute;', 'Ó')
        .replaceAll('&Uacute;', 'Ú')
        .replaceAll('&Ntilde;', 'Ñ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#225;', 'á')
        .replaceAll('&#233;', 'é')
        .replaceAll('&#237;', 'í')
        .replaceAll('&#243;', 'ó')
        .replaceAll('&#250;', 'ú')
        .replaceAll('&#241;', 'ñ');
  }

  static String _formatIngredientName(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  static String _formatTitle(String title) {
    return title
        .split(' ')
        .map((String word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
