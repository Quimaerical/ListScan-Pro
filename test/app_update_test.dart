import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shopliist_pro/features/settings/data/services/app_update_service.dart';
import 'package:shopliist_pro/features/settings/domain/models/app_update_info.dart';
import 'package:shopliist_pro/features/shopping_lists/presentation/widgets/update_notification_banner.dart';

void main() {
  group('AppUpdateInfo Version Comparison Tests', () {
    test('compares semantic versions correctly', () {
      expect(AppUpdateInfo.compareVersions('1.0.4', '1.0.2'), equals(1));
      expect(AppUpdateInfo.compareVersions('1.0.2', '1.0.4'), equals(-1));
      expect(AppUpdateInfo.compareVersions('1.0.4', '1.0.4'), equals(0));
      expect(AppUpdateInfo.compareVersions('1.1.0', '1.0.9'), equals(1));
      expect(AppUpdateInfo.compareVersions('2.0.0', '1.9.9'), equals(1));
    });

    test('parses semantic version from strings with prefixes', () {
      expect(AppUpdateInfo.parseSemanticVersion('v1.0.4'), equals('1.0.4'));
      expect(AppUpdateInfo.parseSemanticVersion('beta v1.0.2'), equals('1.0.2'));
      expect(AppUpdateInfo.parseSemanticVersion('Release 1.2.3-patch'), equals('1.2.3'));
    });

    test('parses GitHub release payload and identifies update availability', () {
      final json = <String, dynamic>{
        'tag_name': 'v1.0.4',
        'name': 'v1.0.4 Actualizacion',
        'body': 'Nuevas mejoras de rendimiento y detector de actualizaciones.',
        'html_url': 'https://github.com/Quimaerical/ListScan-Pro/releases/tag/v1.0.4',
        'published_at': '2026-10-18T23:00:00Z',
        'assets': [
          {
            'name': 'ListScanPro.apk',
            'browser_download_url':
                'https://github.com/Quimaerical/ListScan-Pro/releases/download/v1.0.4/ListScanPro.apk',
          }
        ],
      };

      // When current version is 1.0.2, update is available
      final updateAvail = AppUpdateInfo.fromGitHubJson(
        json: json,
        currentVersion: '1.0.2',
      );
      expect(updateAvail.hasUpdate, isTrue);
      expect(updateAvail.latestVersion, equals('1.0.4'));
      expect(updateAvail.apkDownloadUrl, contains('ListScanPro.apk'));

      // When current version is already 1.0.4, no update needed
      final upToDate = AppUpdateInfo.fromGitHubJson(
        json: json,
        currentVersion: '1.0.4',
      );
      expect(upToDate.hasUpdate, isFalse);
    });
  });

  group('AppUpdateService Tests', () {
    test('fetches and parses update info on 200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.0.5',
            'name': 'v1.0.5',
            'body': 'Notas de la versión.',
            'html_url': 'https://github.com/Quimaerical/ListScan-Pro/releases/tag/v1.0.5',
            'assets': [
              {
                'name': 'app.apk',
                'browser_download_url': 'https://github.com/Quimaerical/ListScan-Pro/app.apk',
              }
            ],
          }),
          200,
        );
      });

      final service = AppUpdateService(client: mockClient);
      final info = await service.checkForUpdates(currentVersion: '1.0.4');

      expect(info, isNotNull);
      expect(info!.hasUpdate, isTrue);
      expect(info.latestVersion, equals('1.0.5'));
    });

    test('returns null on network error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network unreachable');
      });

      final service = AppUpdateService(client: mockClient);
      final info = await service.checkForUpdates();

      expect(info, isNull);
    });
  });

  group('UpdateNotificationBanner Widget Tests', () {
    testWidgets('renders banner, shows release notes and opens guide dialog', (
      WidgetTester tester,
    ) async {
      bool dismissed = false;
      const update = AppUpdateInfo(
        latestVersion: '1.0.5',
        currentVersion: '1.0.4',
        hasUpdate: true,
        releaseName: 'v1.0.5',
        releaseNotes: 'Corrección de errores y nueva vista.',
        releaseUrl: 'https://github.com/Quimaerical/ListScan-Pro/releases',
        apkDownloadUrl: 'https://github.com/Quimaerical/ListScan-Pro/releases/download/v1.0.5/ListScanPro.apk',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNotificationBanner(
              updateInfo: update,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('Nueva versión disponible (1.0.5)'), findsOneWidget);
      expect(find.text('Versión actual: v1.0.4'), findsOneWidget);
      expect(find.text('Descargar Actualización'), findsOneWidget);
      expect(find.text('¿Cómo instalar la APK?'), findsOneWidget);

      // Tap dismiss icon
      await tester.tap(find.byTooltip('Cerrar aviso'));
      await tester.pump();
      expect(dismissed, isTrue);

      // Tap guide button to open installation dialog
      await tester.tap(find.text('¿Cómo instalar la APK?'));
      await tester.pumpAndSettle();

      expect(find.text('Instalar APK en Android'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('Instalar APK en Android'), findsNothing);
    });
  });
}
