import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shopliist_pro/core/network/api_client.dart';
import 'package:shopliist_pro/core/network/api_exceptions.dart';

void main() {
  group('ApiClient Tests', () {
    test('successful GET request returns parsed JSON', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/test');
        expect(request.url.queryParameters['q'], 'pasta');
        return http.Response(
          jsonEncode({
            'meals': [
              {'id': '1', 'name': 'Pasta'},
            ],
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com/api',
        client: mockClient,
      );

      final result = await apiClient.get(
        '/test',
        queryParameters: {'q': 'pasta'},
      );
      expect(result, isA<Map<String, dynamic>>());
      expect(result['meals'][0]['name'], 'Pasta');
    });

    test('401 response throws UnauthorizedException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Invalid token'}), 401);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        client: mockClient,
      );

      expect(
        () => apiClient.get('/secure'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('404 response throws NotFoundException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Meal not found'}), 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        client: mockClient,
      );

      expect(
        () => apiClient.get('/notfound'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test(
      '422 response throws ValidationException with mapped errors',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'query': ['The query field is required.'],
              },
            }),
            422,
          );
        });

        final apiClient = ApiClient(
          baseUrl: 'https://example.com',
          client: mockClient,
        );

        expect(
          () => apiClient.get('/validate'),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.errors['query']?.first,
              'first error',
              'The query field is required.',
            ),
          ),
        );
      },
    );

    test('429 response throws RateLimitException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Too many requests', 429);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        client: mockClient,
      );

      expect(
        () => apiClient.get('/rate-limited'),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('500 response throws ServerException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        client: mockClient,
      );

      expect(() => apiClient.get('/error'), throwsA(isA<ServerException>()));
    });
  });
}
