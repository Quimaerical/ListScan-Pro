import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/features/ocr_scan/domain/models/ocr_recognized_item.dart';
import 'package:shopliist_pro/features/ocr_scan/domain/services/ocr_service.dart';
import 'package:shopliist_pro/features/ocr_scan/presentation/controllers/ocr_scan_controller.dart';

class MockOcrService implements OcrService {
  bool isDisposed = false;
  List<OcrRecognizedItem> mockResult = <OcrRecognizedItem>[];

  @override
  Future<List<OcrRecognizedItem>> processImage(String imagePath) async {
    return mockResult;
  }

  @override
  void dispose() {
    isDisposed = true;
  }
}

void main() {
  group('OcrScanController Tests', () {
    test('toggles selection, selects all and edits items smoothly', () async {
      final mockService = MockOcrService();
      mockService.mockResult = <OcrRecognizedItem>[
        const OcrRecognizedItem(
          id: '1',
          originalText: 'Arroz',
          cleanedName: 'Arroz',
          isSelected: true,
        ),
        const OcrRecognizedItem(
          id: '2',
          originalText: 'Frijoles',
          cleanedName: 'Frijoles',
          isSelected: true,
        ),
      ];

      final controller = OcrScanController(ocrService: mockService);

      await controller.scanExistingPath('/dummy/path.jpg');

      expect(controller.totalCount, equals(2));
      expect(controller.selectedCount, equals(2));
      expect(controller.allSelected, isTrue);

      // Toggle item 1
      controller.toggleItemSelection('1');
      expect(controller.selectedCount, equals(1));
      expect(controller.allSelected, isFalse);

      // Select all false
      controller.selectAll(false);
      expect(controller.selectedCount, equals(0));

      // Select all true
      controller.selectAll(true);
      expect(controller.selectedCount, equals(2));

      // Update item name
      controller.updateItemName('1', 'Arroz Integral');
      expect(controller.items[0].cleanedName, equals('Arroz Integral'));

      // Remove item
      controller.removeItem('2');
      expect(controller.totalCount, equals(1));

      // Dispose releases native resources
      controller.dispose();
      expect(mockService.isDisposed, isTrue);
    });

    test('preserves bounding boxes for interactive visual selection', () async {
      final mockService = MockOcrService();
      mockService.mockResult = <OcrRecognizedItem>[
        const OcrRecognizedItem(
          id: 'b1',
          originalText: 'Pan',
          cleanedName: 'Pan',
          isSelected: true,
          boundingBox: Rect.fromLTRB(10, 10, 80, 40),
        ),
      ];

      final controller = OcrScanController(ocrService: mockService);
      await controller.scanExistingPath('/dummy/receipt.jpg');

      expect(controller.items.first.boundingBox, isNotNull);
      expect(controller.items.first.boundingBox!.width, equals(70.0));

      controller.toggleItemSelection('b1');
      expect(controller.items.first.isSelected, isFalse);
      expect(
        controller.items.first.boundingBox,
        equals(const Rect.fromLTRB(10, 10, 80, 40)),
      );
    });
  });
}
