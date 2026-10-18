import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/features/ocr_scan/domain/models/ocr_recognized_item.dart';

void main() {
  group('OcrRecognizedItem Model', () {
    test(
      'serializes toMap and deserializes fromMap correctly with boundingBox',
      () {
        const item = OcrRecognizedItem(
          id: 'ocr-1',
          originalText: '2 kg Manzanas \$3.99',
          cleanedName: 'Manzanas',
          quantity: '2 kg',
          isSelected: true,
          boundingBox: Rect.fromLTRB(10.0, 20.0, 150.0, 60.0),
        );

        final map = item.toMap();
        expect(map['id'], equals('ocr-1'));
        expect(map['original_text'], equals('2 kg Manzanas \$3.99'));
        expect(map['cleaned_name'], equals('Manzanas'));
        expect(map['quantity'], equals('2 kg'));
        expect(map['is_selected'], equals(1));
        expect(map['bounding_box'], isNotNull);
        expect(map['bounding_box']['left'], equals(10.0));
        expect(map['bounding_box']['top'], equals(20.0));
        expect(map['bounding_box']['right'], equals(150.0));
        expect(map['bounding_box']['bottom'], equals(60.0));

        final restored = OcrRecognizedItem.fromMap(map);
        expect(restored, equals(item));
        expect(
          restored.boundingBox,
          equals(const Rect.fromLTRB(10.0, 20.0, 150.0, 60.0)),
        );
      },
    );

    test('copyWith updates properties properly', () {
      const item = OcrRecognizedItem(
        id: 'ocr-2',
        originalText: 'Leche',
        cleanedName: 'Leche',
        isSelected: true,
      );

      final deselected = item.copyWith(isSelected: false);
      expect(deselected.isSelected, isFalse);
      expect(deselected.cleanedName, equals('Leche'));

      final edited = item.copyWith(cleanedName: 'Leche de Almendras');
      expect(edited.cleanedName, equals('Leche de Almendras'));
    });
  });
}
