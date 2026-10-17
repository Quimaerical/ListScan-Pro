import '../models/ocr_recognized_item.dart';

/// Abstract contract for OCR text inference engines, isolating domain logic
/// from third-party vendor SDKs.
abstract class OcrService {
  /// Processes an image from a local file path and extracts a list of sanitized shopping items.
  Future<List<OcrRecognizedItem>> processImage(String imagePath);

  /// Releases native memory resources (e.g. C++ recognizers).
  void dispose();
}
