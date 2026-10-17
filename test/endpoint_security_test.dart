import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/config/endpoint_security.dart';

void main() {
  group('EndpointSecurity', () {
    test('correctly decodes obfuscated TheMealDB URL with XOR key 0x5A', () {
      final url = EndpointSecurity.getMealDbBaseUrl();
      expect(url, equals('https://www.themealdb.com/api/json/v1/1/'));
    });

    test('decodeXor properly decrypts arbitrary XOR arrays', () {
      const key = 0x5A;
      const original = 'test_string_123';
      final encoded = original.codeUnits.map((c) => c ^ key).toList();

      final decoded = EndpointSecurity.decodeXor(encoded, key);
      expect(decoded, equals(original));
    });
  });
}
