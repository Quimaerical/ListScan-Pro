import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/regex_sanitizer.dart';
import '../../domain/models/ocr_recognized_item.dart';
import '../../domain/services/ocr_service.dart';

/// Implementation of [OcrService] backed by Google ML Kit Latin Text Recognition.
/// Strictly invokes `close()` on the native C++ recognizer to guarantee memory safety.
class MlKitOcrService implements OcrService {
  final TextRecognizer _textRecognizer;
  static const Uuid _uuid = Uuid();
  bool _isDisposed = false;

  MlKitOcrService({TextRecognizer? textRecognizer})
    : _textRecognizer =
          textRecognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<List<OcrRecognizedItem>> processImage(String imagePath) async {
    if (_isDisposed) {
      throw StateError(
        'Cannot process image after MlKitOcrService has been disposed.',
      );
    }

    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    final List<OcrRecognizedItem> items = <OcrRecognizedItem>[];
    final Set<String> seenNames = <String>{};

    for (final TextBlock block in recognizedText.blocks) {
      for (final TextLine line in block.lines) {
        final OcrCleanResult cleanResult = RegexSanitizer.cleanLine(line.text);

        if (!cleanResult.isValid) continue;

        final String normalizedKey = cleanResult.name.toLowerCase();
        if (seenNames.contains(normalizedKey)) continue;
        seenNames.add(normalizedKey);

        items.add(
          OcrRecognizedItem(
            id: _uuid.v4(),
            originalText: line.text,
            cleanedName: cleanResult.name,
            quantity: cleanResult.quantity,
            isSelected: true,
            boundingBox: line.boundingBox,
          ),
        );
      }
    }

    return items;
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _textRecognizer.close();
    }
  }
}
