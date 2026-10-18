import 'package:flutter_test/flutter_test.dart';
import 'package:shopliist_pro/core/utils/regex_sanitizer.dart';

void main() {
  group('RegexSanitizer Tests', () {
    test('filters out common supermarket receipt noise lines', () {
      final noiseLines = <String>[
        'TOTAL \$45.50',
        'SUBTOTAL 38.20 €',
        'IVA 21% INCLUIDO',
        'CAJA 04 - TERMINAL 102',
        'TICKET FACTURA SIMPLIFICADA',
        'PAGO CON TARJETA VISA',
        'CAMBIO 4.50 USD',
        'FECHA 16/10/2026',
        '14:35:10',
        '12345678901234',
        'GRACIAS POR SU VISITA',
        '---',
        '***',
      ];

      for (final line in noiseLines) {
        final result = RegexSanitizer.cleanLine(line);
        expect(
          result.isValid,
          isFalse,
          reason: 'Expected "$line" to be considered invalid noise.',
        );
      }
    });

    test('strips prices and keeps clean product names', () {
      final line1 = RegexSanitizer.cleanLine('Manzanas Gala \$4.99');
      expect(line1.isValid, isTrue);
      expect(line1.name, equals('Manzanas Gala'));

      final line2 = RegexSanitizer.cleanLine('12,50 € Queso Parmesano');
      expect(line2.isValid, isTrue);
      expect(line2.name, equals('Queso Parmesano'));
    });

    test('extracts prefix physical quantities accurately', () {
      final line1 = RegexSanitizer.cleanLine('2 kg Plátanos maduros');
      expect(line1.isValid, isTrue);
      expect(line1.name, equals('Plátanos maduros'));
      expect(line1.quantity, equals('2 kg'));

      final line2 = RegexSanitizer.cleanLine('1.5 L Leche deslactosada');
      expect(line2.isValid, isTrue);
      expect(line2.name, equals('Leche deslactosada'));
      expect(line2.quantity, equals('1.5 L'));

      final line3 = RegexSanitizer.cleanLine('3 pzas Jabón de tocador');
      expect(line3.isValid, isTrue);
      expect(line3.name, equals('Jabón de tocador'));
      expect(line3.quantity, equals('3 pzas'));
    });

    test('extracts suffix quantities', () {
      final line = RegexSanitizer.cleanLine('Harina de trigo 1 kg');
      expect(line.isValid, isTrue);
      expect(line.name, equals('Harina de trigo'));
      expect(line.quantity, equals('1 kg'));
    });

    test('removes bullets and leading punctuation marks', () {
      final line = RegexSanitizer.cleanLine('- [ ] Pan integral de centeno');
      expect(line.isValid, isTrue);
      expect(line.name, equals('Pan integral de centeno'));

      final line2 = RegexSanitizer.cleanLine('* • Aguacates Hass •');
      expect(line2.isValid, isTrue);
      expect(line2.name, equals('Aguacates Hass'));
    });

    test('preserves grocery products containing "caja" or "importado"', () {
      final line1 = RegexSanitizer.cleanLine('Caja de galletas');
      expect(line1.isValid, isTrue);
      expect(line1.name, equals('Caja de galletas'));

      final line2 = RegexSanitizer.cleanLine('Cerveza importada');
      expect(line2.isValid, isTrue);
      expect(line2.name, equals('Cerveza importada'));

      final line3 = RegexSanitizer.cleanLine('1 caja de leche 1,20');
      expect(line3.isValid, isTrue);
      expect(line3.name, equals('Leche'));
      expect(line3.quantity, equals('1 caja de'));
    });

    test('strips trailing receipt prices without currency symbol', () {
      final line1 = RegexSanitizer.cleanLine('LECHE ENTERA 1.25');
      expect(line1.isValid, isTrue);
      expect(line1.name, equals('Leche entera'));

      final line2 = RegexSanitizer.cleanLine('PAN DE MOLDE 0,85 A');
      expect(line2.isValid, isTrue);
      expect(line2.name, equals('Pan de molde'));
    });

    test('strips list numbering prefixes', () {
      final line1 = RegexSanitizer.cleanLine('1. Manzanas rojas');
      expect(line1.isValid, isTrue);
      expect(line1.name, equals('Manzanas rojas'));

      final line2 = RegexSanitizer.cleanLine('2) Plátanos de Canarias');
      expect(line2.isValid, isTrue);
      expect(line2.name, equals('Plátanos de Canarias'));
    });

    test('extracts multiplier prefix e.g. 2x', () {
      final line = RegexSanitizer.cleanLine('2x Aceite de oliva');
      expect(line.isValid, isTrue);
      expect(line.name, equals('Aceite de oliva'));
      expect(line.quantity, equals('2x'));
    });
  });
}
