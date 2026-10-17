import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/features/ocr_scan/domain/models/ocr_recognized_item.dart';
import 'package:shopliist_pro/features/ocr_scan/presentation/widgets/ocr_interactive_image_viewer.dart';

void main() {
  group('OcrInteractiveImageViewer Tests', () {
    late File dummyFile;

    setUpAll(() {
      dummyFile = File('${Directory.systemTemp.path}/test_ocr_image.png');
      dummyFile.writeAsBytesSync(<int>[0, 0, 0, 0]);
    });

    tearDownAll(() {
      if (dummyFile.existsSync()) {
        dummyFile.deleteSync();
      }
    });

    testWidgets('renders interactive bounding boxes and handles box tap', (WidgetTester tester) async {
      String? toggledId;

      const List<OcrRecognizedItem> items = <OcrRecognizedItem>[
        OcrRecognizedItem(
          id: 'item-1',
          originalText: 'Leche 1L',
          cleanedName: 'Leche',
          quantity: '1L',
          isSelected: true,
          boundingBox: Rect.fromLTRB(20.0, 20.0, 120.0, 60.0),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400.0,
              height: 600.0,
              child: OcrInteractiveImageViewer(
                imagePath: dummyFile.path,
                imageSize: const Size(400.0, 600.0),
                items: items,
                onToggleItem: (String id) {
                  toggledId = id;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(OcrInteractiveImageViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Tap on the bounding box position (e.g. Offset(70.0, 40.0) inside Rect(20, 20, 120, 60))
      await tester.tapAt(const Offset(70.0, 40.0));
      await tester.pumpAndSettle();

      expect(toggledId, equals('item-1'));
    });
  });
}
