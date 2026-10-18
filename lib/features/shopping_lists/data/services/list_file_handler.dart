import 'package:uuid/uuid.dart';
import '../../domain/models/shopping_item.dart';
import '../../domain/models/shopping_list.dart';

/// Service responsible for serializing and deserializing shopping lists
/// to and from universal open formats (Markdown checklist and RFC 4180 CSV).
class ListFileHandler {
  static const Uuid _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // MARKDOWN (.md) SUPPORT
  // ---------------------------------------------------------------------------

  /// Exports a [ShoppingList] into standard Markdown with checklist syntax.
  static String exportToMarkdown(ShoppingList list) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('# ${list.title}');
    buffer.writeln();

    for (final ShoppingItem item in list.items) {
      if (item.isSeparator) {
        if (item.name.trim().isNotEmpty) {
          buffer.writeln();
          buffer.writeln('--- ${item.name.trim()} ---');
          buffer.writeln();
        } else {
          buffer.writeln();
          buffer.writeln('---');
          buffer.writeln();
        }
        continue;
      }

      final String check = item.isCompleted ? '[x]' : '[ ]';
      final String amountPrefix = item.amount > 1 ? '${item.amount}x ' : '';
      final String qtyPrefix =
          (item.quantity != null && item.quantity!.trim().isNotEmpty)
          ? '${item.quantity!.trim()} '
          : '';
      final String priceSuffix =
          item.price != null ? ' (\$${item.price!.toStringAsFixed(2)})' : '';
      buffer.writeln('- $check $amountPrefix$qtyPrefix${item.name.trim()}$priceSuffix');
    }

    if (list.hasPrices) {
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln('**Total estimado: \$${list.totalPrice.toStringAsFixed(2)}**');
    }

    return buffer.toString();
  }

  /// Parses Markdown content into a hydrated [ShoppingList] with items.
  static ShoppingList parseMarkdown({
    required String content,
    String defaultTitle = 'Lista Importada',
  }) {
    final String listId = _uuid.v4();
    final List<String> lines = content.split(RegExp(r'\r?\n'));
    String detectedTitle = defaultTitle;

    final RegExp titleRegex = RegExp(r'^#\s+(.+)$');
    for (final String rawLine in lines) {
      final String line = rawLine.trim();
      final Match? titleMatch = titleRegex.firstMatch(line);
      if (titleMatch != null) {
        final String parsedTitle = titleMatch.group(1)?.trim() ?? '';
        if (parsedTitle.isNotEmpty) {
          detectedTitle = parsedTitle;
          break;
        }
      }
    }

    final List<ShoppingItem> items = parseMarkdownItems(
      content: content,
      listId: listId,
    );

    final DateTime now = DateTime.now();
    return ShoppingList(
      id: listId,
      title: detectedTitle,
      colorIndex: 0,
      isPinned: false,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
      items: items,
    );
  }

  /// Parses Markdown content or multiline text into a list of [ShoppingItem]s bound to [listId].
  static List<ShoppingItem> parseMarkdownItems({
    required String content,
    required String listId,
    int startingSortOrder = 0,
  }) {
    final List<String> lines = content.split(RegExp(r'\r?\n'));
    final List<ShoppingItem> items = <ShoppingItem>[];
    final DateTime now = DateTime.now();

    final RegExp headerRegex = RegExp(r'^#+\s+(.+)$');
    final RegExp separatorRegex = RegExp(
      r'^(?:---|###|___|\*\*\*)\s*(.*?)(?:\s*(?:---|###|___|\*\*\*))?$',
    );
    final RegExp checklistRegex = RegExp(r'^[-*•]\s+\[([ xX])\]\s*(.*)$');
    final RegExp bulletRegex = RegExp(r'^[-*•]\s+(.*)$');
    final RegExp numberedRegex = RegExp(r'^\d+[\.\)\-]\s+(.*)$');
    final RegExp multMatcher = RegExp(r'^(\d+)\s*[xX]\s+(.+)$');
    final RegExp prefixQtyMatcher = RegExp(
      r'^(\d+(?:[.,]\d+)?\s*(?:kg|g|gr|l|lt|litro|litros|ml|oz|lb|unid|pza|pzas|uds|ud|botellas|paquetes|latas|cajas)?(?:\s+de)?)\s+(.+)$',
      caseSensitive: false,
    );
    final RegExp suffixQtyMatcher = RegExp(
      r'^(.+?)\s+(\d+(?:[.,]\d+)?\s*(?:kg|g|gr|l|lt|litro|litros|ml|oz|lb|unid|pza|pzas|uds|ud|botellas|paquetes|latas|cajas)?)$',
      caseSensitive: false,
    );

    int sortOrder = startingSortOrder;

    for (final String rawLine in lines) {
      final String line = rawLine.trim();
      if (line.isEmpty) continue;

      // Ignore the primary list title header "# Title" if at the very beginning
      if (line.startsWith('# ') && items.isEmpty) {
        continue;
      }

      // Extract visual separators (e.g. "--- Separador ---" or "---" or "### Frutas")
      final Match? sepMatch = separatorRegex.firstMatch(line);
      if (sepMatch != null) {
        final String label = sepMatch.group(1)?.trim() ?? '';
        items.add(
          ShoppingItem(
            id: _uuid.v4(),
            listId: listId,
            name: label,
            isSeparator: true,
            sortOrder: sortOrder++,
            createdAt: now,
          ),
        );
        continue;
      }

      // Sub-headings like "## Bebidas" also act as labelled separators
      final Match? headerMatch = headerRegex.firstMatch(line);
      if (headerMatch != null) {
        final String label = headerMatch.group(1)?.trim() ?? '';
        items.add(
          ShoppingItem(
            id: _uuid.v4(),
            listId: listId,
            name: label,
            isSeparator: true,
            sortOrder: sortOrder++,
            createdAt: now,
          ),
        );
        continue;
      }

      // Match checklist item "- [ ] item" or "- [x] item"
      final Match? checkMatch = checklistRegex.firstMatch(line);
      bool isCompleted = false;
      String rawText = '';

      if (checkMatch != null) {
        final String mark = checkMatch.group(1) ?? ' ';
        isCompleted = mark.toLowerCase() == 'x';
        rawText = checkMatch.group(2)?.trim() ?? '';
      } else {
        // Match bullet item "- item", "* item", "• item"
        final Match? bulletMatch = bulletRegex.firstMatch(line);
        if (bulletMatch != null) {
          rawText = bulletMatch.group(1)?.trim() ?? '';
        } else {
          // Match numbered item "1. item", "2) item"
          final Match? numMatch = numberedRegex.firstMatch(line);
          if (numMatch != null) {
            rawText = numMatch.group(1)?.trim() ?? '';
          } else {
            // Plain line of text
            rawText = line;
          }
        }
      }

      if (rawText.isEmpty) continue;

      // Check multiplier prefix e.g. "3x Cervezas" or "2X Leche"
      int amount = 1;
      String fullText = rawText;
      final Match? matchMult = multMatcher.firstMatch(rawText);
      if (matchMult != null) {
        amount = int.tryParse(matchMult.group(1) ?? '1') ?? 1;
        fullText = matchMult.group(2)?.trim() ?? rawText;
      }

      // Check optional price suffix e.g. "($3.50)" or "(3.50)" or "($12)"
      double? price;
      final RegExp priceMatcher = RegExp(
        r'\(\s*\$?\s*(\d+(?:[.,]\d{1,2})?)\s*\)\s*$',
      );
      final Match? priceMatch = priceMatcher.firstMatch(fullText);
      if (priceMatch != null) {
        final String rawPrice = priceMatch.group(1)!.replaceAll(',', '.');
        price = double.tryParse(rawPrice);
        fullText = fullText.substring(0, priceMatch.start).trim();
      }

      // Try extracting quantity prefix ("2 kg Manzanas") or suffix ("Harina 1 kg")
      String? quantity;
      String name = fullText;

      final Match? prefixMatch = prefixQtyMatcher.firstMatch(fullText);
      if (prefixMatch != null) {
        quantity = prefixMatch.group(1)?.trim();
        name = prefixMatch.group(2)?.trim() ?? fullText;
      } else {
        final Match? suffixMatch = suffixQtyMatcher.firstMatch(fullText);
        if (suffixMatch != null) {
          name = suffixMatch.group(1)?.trim() ?? fullText;
          quantity = suffixMatch.group(2)?.trim();
        }
      }

      items.add(
        ShoppingItem(
          id: _uuid.v4(),
          listId: listId,
          name: name,
          quantity: quantity,
          amount: ShoppingItem.clampAmount(amount),
          price: price,
          isCompleted: isCompleted,
          sortOrder: sortOrder++,
          createdAt: now,
        ),
      );
    }

    return items;
  }

  // ---------------------------------------------------------------------------
  // CSV (RFC 4180) SUPPORT
  // ---------------------------------------------------------------------------

  /// Exports a [ShoppingList] into standard CSV format.
  static String exportToCsv(ShoppingList list) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('name,quantity,is_completed,category,amount,price');

    for (final ShoppingItem item in list.items) {
      final String nameEscaped = _escapeCsvField(item.name);
      final String qtyEscaped = _escapeCsvField(item.quantity ?? '');
      final String completed = item.isCompleted ? '1' : '0';
      final String catEscaped = _escapeCsvField(item.category ?? '');
      final String priceStr =
          item.price != null ? item.price!.toStringAsFixed(2) : '';

      buffer.writeln(
        '$nameEscaped,$qtyEscaped,$completed,$catEscaped,${item.amount},$priceStr',
      );
    }

    return buffer.toString();
  }

  /// Parses CSV content into a hydrated [ShoppingList].
  static ShoppingList parseCsv({
    required String content,
    String defaultTitle = 'Lista CSV Importada',
  }) {
    final List<List<String>> rows = _parseCsvRows(content);
    final String listId = _uuid.v4();
    final DateTime now = DateTime.now();
    final List<ShoppingItem> items = <ShoppingItem>[];

    int sortOrder = 0;
    bool isHeader = true;

    for (final List<String> cols in rows) {
      if (cols.isEmpty) continue;

      // Skip CSV header if present
      if (isHeader) {
        isHeader = false;
        final String firstCol = cols[0].toLowerCase().trim();
        if (firstCol == 'name' || firstCol == 'nombre' || firstCol == 'item') {
          continue;
        }
      }

      final String name = cols.isNotEmpty ? cols[0].trim() : '';
      if (name.isEmpty) continue;

      final String quantity = (cols.length > 1 && cols[1].trim().isNotEmpty)
          ? cols[1].trim()
          : '';
      final String completedRaw = cols.length > 2 ? cols[2].trim() : '0';
      final bool isCompleted =
          completedRaw == '1' || completedRaw.toLowerCase() == 'true';
      final String category = (cols.length > 3 && cols[3].trim().isNotEmpty)
          ? cols[3].trim()
          : '';
      final String amountRaw = cols.length > 4 ? cols[4].trim() : '1';
      final int amount = int.tryParse(amountRaw) ?? 1;
      final String priceRaw = cols.length > 5 ? cols[5].trim() : '';
      final double? price = priceRaw.isNotEmpty
          ? double.tryParse(priceRaw.replaceAll(',', '.'))
          : null;

      items.add(
        ShoppingItem(
          id: _uuid.v4(),
          listId: listId,
          name: name,
          quantity: quantity.isNotEmpty ? quantity : null,
          category: category.isNotEmpty ? category : null,
          amount: ShoppingItem.clampAmount(amount),
          price: price,
          isCompleted: isCompleted,
          sortOrder: sortOrder++,
          createdAt: now,
        ),
      );
    }

    return ShoppingList(
      id: listId,
      title: defaultTitle,
      colorIndex: 1,
      createdAt: now,
      updatedAt: now,
      items: items,
    );
  }

  /// Dispatches import automatically according to the file extension.
  static ShoppingList importFromContent({
    required String filename,
    required String content,
  }) {
    final String cleanTitle = filename
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .trim();
    final String title = cleanTitle.isNotEmpty ? cleanTitle : 'Lista Importada';

    if (filename.toLowerCase().endsWith('.csv')) {
      return parseCsv(content: content, defaultTitle: title);
    } else {
      return parseMarkdown(content: content, defaultTitle: title);
    }
  }

  // Helper: RFC 4180 CSV escaping
  static String _escapeCsvField(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      final String escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  // Helper: RFC 4180 CSV tokenizer
  static List<List<String>> _parseCsvRows(String content) {
    final List<List<String>> rows = <List<String>>[];
    List<String> currentRow = <String>[];
    StringBuffer currentField = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < content.length; i++) {
      final String char = content[i];

      if (char == '"') {
        if (insideQuotes && i + 1 < content.length && content[i + 1] == '"') {
          // Escaped quote: "" -> "
          currentField.write('"');
          i++;
        } else {
          // Toggle quote mode
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        currentRow.add(currentField.toString());
        currentField = StringBuffer();
      } else if ((char == '\n' || char == '\r') && !insideQuotes) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++; // skip \n of \r\n
        }
        currentRow.add(currentField.toString());
        rows.add(currentRow);
        currentRow = <String>[];
        currentField = StringBuffer();
      } else {
        currentField.write(char);
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      rows.add(currentRow);
    }

    return rows;
  }
}
