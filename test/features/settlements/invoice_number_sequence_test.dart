import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/features/settlements/domain/utils/invoice_number_sequence.dart';

void main() {
  group('parseTrailingInvoiceNumber', () {
    test('parses prefixed number', () {
      final parsed = parseTrailingInvoiceNumber('сч-13');
      expect(parsed?.prefix, 'сч-');
      expect(parsed?.value, 13);
    });

    test('parses multi-segment prefix', () {
      final parsed = parseTrailingInvoiceNumber('217-3');
      expect(parsed?.prefix, '217-');
      expect(parsed?.value, 3);
    });

    test('parses plain number', () {
      final parsed = parseTrailingInvoiceNumber('2');
      expect(parsed?.prefix, '');
      expect(parsed?.value, 2);
    });

    test('returns null for invalid values', () {
      expect(parseTrailingInvoiceNumber('abc'), isNull);
      expect(parseTrailingInvoiceNumber('сч-'), isNull);
    });
  });

  group('computeNextInvoiceNumber', () {
    test('returns 1 for empty list', () {
      expect(computeNextInvoiceNumber(const []), '1');
    });

    test('increments plain number', () {
      expect(computeNextInvoiceNumber(['2']), '3');
    });

    test('preserves prefix of max suffix', () {
      expect(computeNextInvoiceNumber(['сч-13']), 'сч-14');
      expect(computeNextInvoiceNumber(['217-3']), '217-4');
    });

    test('uses global max suffix across prefixes', () {
      expect(
        computeNextInvoiceNumber(['сч-13', '217-20']),
        '217-21',
      );
    });

    test('skips unparseable numbers', () {
      expect(computeNextInvoiceNumber(['abc', 'сч-13']), 'сч-14');
    });

    test('strips leading zeros in suffix', () {
      expect(computeNextInvoiceNumber(['INV 001']), 'INV 2');
      expect(computeNextInvoiceNumber(['012']), '13');
    });

    test('handles two-digit sequence', () {
      expect(computeNextInvoiceNumber(['9', '10']), '11');
      expect(computeNextInvoiceNumber(['сч-9', 'сч-10']), 'сч-11');
    });
  });
}
