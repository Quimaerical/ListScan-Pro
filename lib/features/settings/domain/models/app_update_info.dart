/// Domain model representing GitHub release update information.
class AppUpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final bool hasUpdate;
  final String releaseName;
  final String releaseNotes;
  final String releaseUrl;
  final String? apkDownloadUrl;
  final DateTime? publishedAt;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.hasUpdate,
    required this.releaseName,
    required this.releaseNotes,
    required this.releaseUrl,
    this.apkDownloadUrl,
    this.publishedAt,
  });

  /// Factory constructor to parse GitHub API release payload.
  factory AppUpdateInfo.fromGitHubJson({
    required Map<String, dynamic> json,
    required String currentVersion,
  }) {
    final String tagName = (json['tag_name'] as String? ?? '').trim();
    final String name = (json['name'] as String? ?? '').trim();
    final String body = (json['body'] as String? ?? '').trim();
    final String htmlUrl = (json['html_url'] as String? ?? '').trim();
    final String? publishedAtStr = json['published_at'] as String?;
    final DateTime? publishedAt =
        publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

    // Extract clean semantic version string (e.g., from 'v1.0.4', 'beta v1.0.4', '1.0.4')
    final String latestVer = parseSemanticVersion(name.isNotEmpty ? name : tagName);

    // Locate direct APK asset download URL if provided in assets list
    String? apkUrl;
    final dynamic assets = json['assets'];
    if (assets is List) {
      for (final dynamic asset in assets) {
        if (asset is Map<String, dynamic>) {
          final String assetName = (asset['name'] as String? ?? '').toLowerCase();
          if (assetName.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }
    }

    final bool isOutdated = compareVersions(latestVer, currentVersion) > 0;

    return AppUpdateInfo(
      latestVersion: latestVer.isNotEmpty ? latestVer : (tagName.isNotEmpty ? tagName : '1.0.0'),
      currentVersion: currentVersion,
      hasUpdate: isOutdated,
      releaseName: name.isNotEmpty ? name : (tagName.isNotEmpty ? tagName : 'Actualizacion'),
      releaseNotes: body,
      releaseUrl: htmlUrl.isNotEmpty ? htmlUrl : 'https://github.com/Quimaerical/ListScan-Pro/releases',
      apkDownloadUrl: apkUrl,
      publishedAt: publishedAt,
    );
  }

  /// Extracts the major.minor.patch numeric triplet from tags like "beta v1.0.2" -> "1.0.2"
  static String parseSemanticVersion(String raw) {
    final RegExp regExp = RegExp(r'(\d+)\.(\d+)\.(\d+)');
    final Match? match = regExp.firstMatch(raw);
    if (match != null) {
      return match.group(0)!;
    }
    return raw.trim();
  }

  /// Compares two version strings (e.g., "1.0.4" vs "1.0.2").
  /// Returns 1 if v1 > v2, -1 if v1 < v2, and 0 if equal.
  static int compareVersions(String v1, String v2) {
    final List<int> parts1 = _extractNumbers(v1);
    final List<int> parts2 = _extractNumbers(v2);

    final int maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final int p1 = i < parts1.length ? parts1[i] : 0;
      final int p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  static List<int> _extractNumbers(String ver) {
    final RegExp regExp = RegExp(r'\d+');
    return regExp
        .allMatches(ver)
        .map((Match m) => int.tryParse(m.group(0)!) ?? 0)
        .toList();
  }
}
