import 'dart:io';
import 'package:flutter/services.dart';

/// Platform utility to launch external URLs in the default browser.
/// Uses native platform intent on Android, process start on Linux,
/// or system clipboard fallback.
class UrlLauncherHelper {
  const UrlLauncherHelper._();

  /// Launches [url] in the default browser or viewer.
  static Future<bool> launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    try {
      if (Platform.isAndroid) {
        const nativeChannel = MethodChannel('shopliist_pro/native_share');
        try {
          final bool? result = await nativeChannel.invokeMethod<bool>('openBrowser', {'url': url});
          if (result == true) return true;
        } catch (_) {}

        const channel = MethodChannel('plugins.flutter.io/url_launcher');
        try {
          final bool? result = await channel.invokeMethod<bool>('launch', {
            'url': url,
            'useSafariVC': false,
            'useWebView': false,
            'enableJavaScript': false,
            'enableDomStorage': false,
            'universalLinksOnly': false,
            'headers': <String, String>{},
          });
          if (result == true) return true;
        } catch (_) {}
      } else if (Platform.isLinux) {
        final process = await Process.run('xdg-open', [url]);
        if (process.exitCode == 0) return true;
      }
    } catch (_) {
      // Fallback
    }

    // Fallback: Copy URL to clipboard
    await Clipboard.setData(ClipboardData(text: url));
    return true;
  }
}
