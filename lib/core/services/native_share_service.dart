import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lightweight native sharing bridge using Flutter's built-in [MethodChannel].
/// Completely avoids legacy third-party plugins that cause Kotlin Gradle Plugin (KGP)
/// or compilation warnings.
class NativeShareService {
  const NativeShareService._();

  static const MethodChannel _channel = MethodChannel('shopliist_pro/native_share');

  /// Shares [text] directly to other applications via the operating system's
  /// native share sheet (Android Intent.ACTION_SEND / iOS UIActivityViewController).
  /// Falls back to clipboard on desktop/unsupported environments.
  static Future<bool> shareText({
    required String text,
    String title = 'Compartir lista de compras',
  }) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'shareText',
        <String, dynamic>{
          'text': text,
          'title': title,
        },
      );
      return success ?? true;
    } catch (e) {
      debugPrint('NativeShareService: Platform channel unavailable ($e). Fallback to clipboard.');
      await Clipboard.setData(ClipboardData(text: text));
      return false;
    }
  }
}
