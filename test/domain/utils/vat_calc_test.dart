import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/domain/utils/vat_calc.dart';

void main() {
  group('computeVatAmount', () {
    test('included 22% from gross', () {
      expect(
        computeVatAmount(
          baseAmount: 122,
          vatRate: 22,
          isVatIncluded: true,
        ),
        22,
      );
    });

    test('on top 22%', () {
      expect(
        computeVatAmount(
          baseAmount: 100,
          vatRate: 22,
          isVatIncluded: false,
        ),
        22,
      );
    });
  });

  group('splitActAmountForStorage', () {
    test('line total is net, vat on top (ignores contract included flag)', () {
      const lineTotal = 7615809.86;
      final split = splitActAmountForStorage(
        lineTotal: lineTotal,
        vatTerms: const ContractVatTerms(vatRate: 22, isVatIncluded: true),
      );
      expect(split.amount, lineTotal);
      expect(split.vatAmount, closeTo(lineTotal * 0.22, 0.01));
      expect(split.amount + split.vatAmount, greaterThan(lineTotal));
    });

    test('on top: total_to_pay is line + vat', () {
      const lineTotal = 1000.0;
      final split = splitActAmountForStorage(
        lineTotal: lineTotal,
        vatTerms: const ContractVatTerms(vatRate: 22, isVatIncluded: false),
      );
      expect(split.amount, 1000);
      expect(split.vatAmount, 220);
      expect(split.amount + split.vatAmount, 1220);
    });
  });
}
