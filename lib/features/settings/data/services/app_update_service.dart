import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/endpoint_security.dart';
import '../../domain/models/app_update_info.dart';

/// Service that checks for GitHub public releases to detect newer app versions.
class AppUpdateService {
  final http.Client _client;

  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  /// Default application version identifier for build v1.0.4.
  static const String currentAppVersion = '1.0.4';

  /// Queries the GitHub repository release endpoint and parses update information.
  /// Returns null if offline, request times out, or no release is found.
  Future<AppUpdateInfo?> checkForUpdates({
    String currentVersion = currentAppVersion,
  }) async {
    try {
      final String url = EndpointSecurity.getGitHubLatestReleaseApiUrl();
      final Uri uri = Uri.parse(url);

      final http.Response response = await _client.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'ListScan-Pro-App',
        },
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return AppUpdateInfo.fromGitHubJson(
            json: decoded,
            currentVersion: currentVersion,
          );
        }
      }
    } catch (_) {
      // Gracefully handle connectivity timeouts or network errors
    }
    return null;
  }
}
