/// Represents a single text line recognized and parsed by the OCR engine.
class OcrRecognizedItem {
  final String id;
  final String originalText;
  final String cleanedName;
  final String? quantity;
  final bool isSelected;

  const OcrRecognizedItem({
    required this.id,
    required this.originalText,
    required this.cleanedName,
    this.quantity,
    this.isSelected = true,
  });

  OcrRecognizedItem copyWith({
    String? id,
    String? originalText,
    String? cleanedName,
    String? quantity,
    bool? isSelected,
  }) {
    return OcrRecognizedItem(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      cleanedName: cleanedName ?? this.cleanedName,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'original_text': originalText,
      'cleaned_name': cleanedName,
      'quantity': quantity,
      'is_selected': isSelected ? 1 : 0,
    };
  }

  factory OcrRecognizedItem.fromMap(Map<String, dynamic> map) {
    return OcrRecognizedItem(
      id: map['id'] as String,
      originalText: map['original_text'] as String,
      cleanedName: map['cleaned_name'] as String,
      quantity: map['quantity'] as String?,
      isSelected: (map['is_selected'] as int? ?? 1) == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OcrRecognizedItem &&
        other.id == id &&
        other.originalText == originalText &&
        other.cleanedName == cleanedName &&
        other.quantity == quantity &&
        other.isSelected == isSelected;
  }

  @override
  int get hashCode => Object.hash(id, originalText, cleanedName, quantity, isSelected);
}
