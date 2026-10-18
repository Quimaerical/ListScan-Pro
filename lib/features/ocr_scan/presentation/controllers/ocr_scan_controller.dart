import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/ocr_recognized_item.dart';
import '../../domain/services/ocr_service.dart';

/// Presentation state controller managing image capture, OCR execution,
/// text line selection and edits using Flutter's native [ChangeNotifier].
class OcrScanController extends ChangeNotifier {
  final OcrService ocrService;
  final ImagePicker _imagePicker;

  OcrScanController({required this.ocrService, ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  String? _imagePath;
  ui.Size? _imageSize;
  bool _isProcessing = false;
  List<OcrRecognizedItem> _items = <OcrRecognizedItem>[];
  String? _errorMessage;

  String? get imagePath => _imagePath;
  ui.Size? get imageSize => _imageSize;
  bool get isProcessing => _isProcessing;
  List<OcrRecognizedItem> get items => _items;
  String? get errorMessage => _errorMessage;

  List<OcrRecognizedItem> get selectedItems =>
      _items.where((OcrRecognizedItem item) => item.isSelected).toList();

  int get selectedCount => selectedItems.length;
  int get totalCount => _items.length;
  bool get allSelected =>
      _items.isNotEmpty && _items.every((OcrRecognizedItem i) => i.isSelected);

  Future<void> pickAndScanImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );

      if (pickedFile == null) return;

      _imagePath = pickedFile.path;
      _errorMessage = null;
      notifyListeners();

      await _runOcrProcessing(pickedFile.path);
    } catch (e) {
      _errorMessage = 'Error al capturar imagen: $e';
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> scanExistingPath(String path) async {
    _imagePath = path;
    _errorMessage = null;
    notifyListeners();
    await _runOcrProcessing(path);
  }

  Future<void> _runOcrProcessing(String path) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _imageSize = await _resolveImageDimensions(path);

      _items = await ocrService.processImage(path);
      if (_items.isEmpty) {
        _errorMessage = 'No se detectó texto de compras legible en la imagen.';
      }
    } catch (e) {
      _errorMessage = 'Error durante el reconocimiento óptico: $e';
      _items = <OcrRecognizedItem>[];
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void toggleItemSelection(String id) {
    final int idx = _items.indexWhere(
      (OcrRecognizedItem item) => item.id == id,
    );
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isSelected: !_items[idx].isSelected);
      notifyListeners();
    }
  }

  void selectAll(bool select) {
    _items = _items
        .map((OcrRecognizedItem item) => item.copyWith(isSelected: select))
        .toList();
    notifyListeners();
  }

  void updateItemName(String id, String newName) {
    if (newName.trim().isEmpty) return;
    final int idx = _items.indexWhere(
      (OcrRecognizedItem item) => item.id == id,
    );
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(cleanedName: newName.trim());
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((OcrRecognizedItem item) => item.id == id);
    notifyListeners();
  }

  void reset() {
    _imagePath = null;
    _imageSize = null;
    _items = <OcrRecognizedItem>[];
    _errorMessage = null;
    _isProcessing = false;
    notifyListeners();
  }

  Future<ui.Size?> _resolveImageDimensions(String path) async {
    try {
      final Completer<ui.Size> completer = Completer<ui.Size>();
      final FileImage fileImage = FileImage(File(path));
      final ImageStream stream = fileImage.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          final ui.Size size = ui.Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          if (!completer.isCompleted) {
            completer.complete(size);
          }
          stream.removeListener(listener);
        },
        onError: (dynamic error, StackTrace? stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      return await completer.future;
    } catch (_) {
      try {
        final Uint8List bytes = await File(path).readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        final ui.Size size = ui.Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        frame.image.dispose();
        codec.dispose();
        return size;
      } catch (_) {
        return null;
      }
    }
  }

  @override
  void dispose() {
    ocrService.dispose();
    super.dispose();
  }
}
