/// Result of cleaning a recognized OCR text line.
class OcrCleanResult {
  final String name;
  final String? quantity;
  final bool isValid;

  const OcrCleanResult({
    required this.name,
    this.quantity,
    required this.isValid,
  });
}

/// Advanced text sanitizer specialized in filtering receipt noise,
/// stripping currency amounts, extracting physical quantities and standardizing product names.
class RegexSanitizer {
  const RegexSanitizer._();

  // Common receipt noise keywords (case-insensitive)
  static final RegExp _receiptNoiseRegex = RegExp(
    r'\b(?:TOTAL|SUBTOTAL|TICKET|FACTURA|BOLETA|RECIBO|IVA|TAX|IMPUESTO|CAJA|CAJERO|'
    r'VISA|MASTERCARD|AMERICAN\s*EXPRESS|DEBITO|CREDITO|EFECTIVO|CASH|CAMBIO|CHANGE|'
    r'DESCUENTO|DISCOUNT|AHORRO|GRACIAS|VUELVA|NIF|CIF|RUC|RUT|TERMINAL|FECHA|HORA|'
    r'AUTORIZACION|CODIGO|ITEMS?|PRECIO|UNITARIO|CANTIDAD|IMPORT)\b',
    caseSensitive: false,
  );

  // Currency price pattern (e.g., $12.50, 12,50 €, USD 9.99, 15.00 EUR)
  static final RegExp _priceRegex = RegExp(
    r'(?:[\$€£]|USD|EUR|CLP|MXN|COP|ARS)\s*\d+(?:[.,]\d+)?|\d+(?:[.,]\d+)?\s*(?:[\$€£]|USD|EUR|CLP|MXN|COP|ARS)',
    caseSensitive: false,
  );

  // Date and time patterns
  static final RegExp _dateTimeRegex = RegExp(
    r'\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}:\d{2}(?::\d{2})?)\b',
  );

  // Barcode / long numeric string pattern
  static final RegExp _barcodeRegex = RegExp(r'^\d{8,20}$');

  // Prefix quantity pattern: "2 kg Manzanas", "1.5 L Leche", "3 pzas Jabón"
  static final RegExp _prefixQtyRegex = RegExp(
    r'^(\d+(?:[.,]\d+)?\s*(?:kg|g|gr|l|lt|litro|litros|ml|oz|lb|unid|uds|ud|pza|pzas|paquete|paquetes|botellas?|latas?|cajas?)?)\s+(.+)$',
    caseSensitive: false,
  );

  // Suffix quantity pattern: "Manzanas 2 kg", "Leche 1 L"
  static final RegExp _suffixQtyRegex = RegExp(
    r'^(.+?)\s+(\d+(?:[.,]\d+)?\s*(?:kg|g|gr|l|lt|litro|litros|ml|oz|lb|unid|uds|ud|pza|pzas|paquete|paquetes|botellas?|latas?|cajas?))$',
    caseSensitive: false,
  );

  /// Cleans an incoming raw OCR line and determines whether it represents a plausible shopping product.
  static OcrCleanResult cleanLine(String rawLine) {
    String text = rawLine.trim();

    if (text.isEmpty) {
      return const OcrCleanResult(name: '', isValid: false);
    }

    // Discard pure barcode / transaction IDs
    if (_barcodeRegex.hasMatch(text.replaceAll(RegExp(r'\s+'), ''))) {
      return const OcrCleanResult(name: '', isValid: false);
    }

    // Discard lines dominated by receipt keywords
    if (_receiptNoiseRegex.hasMatch(text)) {
      return const OcrCleanResult(name: '', isValid: false);
    }

    // Discard lines that are solely dates or times
    if (_dateTimeRegex.hasMatch(text) && text.replaceAll(_dateTimeRegex, '').trim().isEmpty) {
      return const OcrCleanResult(name: '', isValid: false);
    }

    // Strip currency / prices
    text = text.replaceAll(_priceRegex, '').trim();

    // Strip leading checklist brackets e.g. "- [ ] ", "[x] ", "• [ ] "
    text = text.replaceAll(RegExp(r'^(?:[-*•_=|#~>\[\]\(\)]|\s)*\[\s*[xX]?\s*\]\s*'), '').trim();

    // Strip leading bullets, asterisks, brackets, or OCR artifacts (with interior spaces)
    text = text.replaceAll(RegExp(r'^(?:[-*•_=|#~>\[\]\(\)]|\s)+'), '').trim();
    text = text.replaceAll(RegExp(r'(?:[-*•_=|#~>\[\]\(\)]|\s)+$'), '').trim();

    // Collapse multiple internal spaces
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ');

    if (text.length < 2) {
      return const OcrCleanResult(name: '', isValid: false);
    }

    // Attempt to extract quantity and clean product name
    String? detectedQty;
    String cleanName = text;

    final Match? prefixMatch = _prefixQtyRegex.firstMatch(text);
    if (prefixMatch != null) {
      final String qtyCandidate = prefixMatch.group(1)?.trim() ?? '';
      final String nameCandidate = prefixMatch.group(2)?.trim() ?? '';

      // Ensure the remaining candidate is not empty and has letters
      if (nameCandidate.length >= 2 && RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]').hasMatch(nameCandidate)) {
        detectedQty = qtyCandidate;
        cleanName = nameCandidate;
      }
    } else {
      final Match? suffixMatch = _suffixQtyRegex.firstMatch(text);
      if (suffixMatch != null) {
        final String nameCandidate = suffixMatch.group(1)?.trim() ?? '';
        final String qtyCandidate = suffixMatch.group(2)?.trim() ?? '';

        if (nameCandidate.length >= 2 && RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]').hasMatch(nameCandidate)) {
          detectedQty = qtyCandidate;
          cleanName = nameCandidate;
        }
      }
    }

    // Capitalize first letter cleanly
    if (cleanName.isNotEmpty) {
      cleanName = cleanName[0].toUpperCase() + (cleanName.length > 1 ? cleanName.substring(1) : '');
    }

    return OcrCleanResult(
      name: cleanName,
      quantity: detectedQty,
      isValid: cleanName.length >= 2 && RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]').hasMatch(cleanName),
    );
  }
}
