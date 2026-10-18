import 'dart:ui';

/// Represents a single text line recognized and parsed by the OCR engine.
class OcrRecognizedItem {
  final String id;
  final String originalText;
  final String cleanedName;
  final String? quantity;
  final bool isSelected;
  final Rect? boundingBox;

  const OcrRecognizedItem({
    required this.id,
    required this.originalText,
    required this.cleanedName,
    this.quantity,
    this.isSelected = true,
    this.boundingBox,
  });

  OcrRecognizedItem copyWith({
    String? id,
    String? originalText,
    String? cleanedName,
    String? quantity,
    bool? isSelected,
    Rect? boundingBox,
  }) {
    return OcrRecognizedItem(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      cleanedName: cleanedName ?? this.cleanedName,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
      boundingBox: boundingBox ?? this.boundingBox,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'original_text': originalText,
      'cleaned_name': cleanedName,
      'quantity': quantity,
      'is_selected': isSelected ? 1 : 0,
      'bounding_box': boundingBox != null
          ? <String, double>{
              'left': boundingBox!.left,
              'top': boundingBox!.top,
              'right': boundingBox!.right,
              'bottom': boundingBox!.bottom,
            }
          : null,
    };
  }

  factory OcrRecognizedItem.fromMap(Map<String, dynamic> map) {
    Rect? box;
    if (map['bounding_box'] != null) {
      final Map<String, dynamic> boxMap = Map<String, dynamic>.from(
        map['bounding_box'] as Map,
      );
      box = Rect.fromLTRB(
        (boxMap['left'] as num).toDouble(),
        (boxMap['top'] as num).toDouble(),
        (boxMap['right'] as num).toDouble(),
        (boxMap['bottom'] as num).toDouble(),
      );
    }

    return OcrRecognizedItem(
      id: map['id'] as String,
      originalText: map['original_text'] as String,
      cleanedName: map['cleaned_name'] as String,
      quantity: map['quantity'] as String?,
      isSelected: (map['is_selected'] as int? ?? 1) == 1,
      boundingBox: box,
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
        other.isSelected == isSelected &&
        other.boundingBox == boundingBox;
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalText,
    cleanedName,
    quantity,
    isSelected,
    boundingBox,
  );
}
