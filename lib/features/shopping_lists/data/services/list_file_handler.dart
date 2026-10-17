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
      final String check = item.isCompleted ? '[x]' : '[ ]';
      final String qtyPrefix = (item.quantity != null && item.quantity!.trim().isNotEmpty)
          ? '${item.quantity!.trim()} '
          : '';
      buffer.writeln('- $check $qtyPrefix${item.name.trim()}');
    }

    return buffer.toString();
  }

  /// Parses Markdown content into a hydrated [ShoppingList] with items.
  static ShoppingList parseMarkdown({
    required String content,
    String defaultTitle = 'Lista Importada',
  }) {
    final List<String> lines = content.split(RegExp(r'\r?\n'));
    String detectedTitle = defaultTitle;
    final List<ShoppingItem> items = <ShoppingItem>[];
    final String listId = _uuid.v4();
    final DateTime now = DateTime.now();

    final RegExp titleRegex = RegExp(r'^#+\s+(.+)$');
    final RegExp itemRegex = RegExp(r'^[-*]\s+\[([ xX])\]\s*(.*)$');

    int sortOrder = 0;

    for (final String rawLine in lines) {
      final String line = rawLine.trim();
      if (line.isEmpty) continue;

      // Extract list title from the first Markdown header
      final Match? titleMatch = titleRegex.firstMatch(line);
      if (titleMatch != null && detectedTitle == defaultTitle) {
        final String parsedTitle = titleMatch.group(1)?.trim() ?? '';
        if (parsedTitle.isNotEmpty) {
          detectedTitle = parsedTitle;
        }
        continue;
      }

      // Extract checklist items
      final Match? itemMatch = itemRegex.firstMatch(line);
      if (itemMatch != null) {
        final String mark = itemMatch.group(1) ?? ' ';
        final bool isCompleted = mark.toLowerCase() == 'x';
        final String fullText = itemMatch.group(2)?.trim() ?? '';

        if (fullText.isEmpty) continue;

        // Try extracting quantity if starting with digit e.g. "2 kg Manzanas"
        String? quantity;
        String name = fullText;

        final RegExp qtyMatcher = RegExp(r'^(\d+(?:[.,]\d+)?\s*(?:kg|g|l|ml|oz|lb|unid|pza|uds|botellas|paquetes|latas|cajas)?)\s+(.+)$', caseSensitive: false);
        final Match? matchQty = qtyMatcher.firstMatch(fullText);
        if (matchQty != null) {
          quantity = matchQty.group(1)?.trim();
          name = matchQty.group(2)?.trim() ?? fullText;
        }

        items.add(
          ShoppingItem(
            id: _uuid.v4(),
            listId: listId,
            name: name,
            quantity: quantity,
            isCompleted: isCompleted,
            sortOrder: sortOrder++,
            createdAt: now,
          ),
        );
      }
    }

    return ShoppingList(
      id: listId,
      title: detectedTitle,
      colorIndex: 0,
      createdAt: now,
      updatedAt: now,
      items: items,
    );
  }

  // ---------------------------------------------------------------------------
  // CSV (RFC 4180) SUPPORT
  // ---------------------------------------------------------------------------

  /// Exports a [ShoppingList] into standard CSV format.
  static String exportToCsv(ShoppingList list) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('name,quantity,is_completed,category');

    for (final ShoppingItem item in list.items) {
      final String nameEscaped = _escapeCsvField(item.name);
      final String qtyEscaped = _escapeCsvField(item.quantity ?? '');
      final String completed = item.isCompleted ? '1' : '0';
      final String catEscaped = _escapeCsvField(item.category ?? '');

      buffer.writeln('$nameEscaped,$qtyEscaped,$completed,$catEscaped');
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

      final String quantity = (cols.length > 1 && cols[1].trim().isNotEmpty) ? cols[1].trim() : '';
      final String completedRaw = cols.length > 2 ? cols[2].trim() : '0';
      final bool isCompleted = completedRaw == '1' || completedRaw.toLowerCase() == 'true';
      final String category = (cols.length > 3 && cols[3].trim().isNotEmpty) ? cols[3].trim() : '';

      items.add(
        ShoppingItem(
          id: _uuid.v4(),
          listId: listId,
          name: name,
          quantity: quantity.isNotEmpty ? quantity : null,
          category: category.isNotEmpty ? category : null,
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
    final String cleanTitle = filename.replaceAll(RegExp(r'\.[^.]+$'), '').trim();
    final String title = cleanTitle.isNotEmpty ? cleanTitle : 'Lista Importada';

    if (filename.toLowerCase().endsWith('.csv')) {
      return parseCsv(content: content, defaultTitle: title);
    } else {
      return parseMarkdown(content: content, defaultTitle: title);
    }
  }

  // Helper: RFC 4180 CSV escaping
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
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
