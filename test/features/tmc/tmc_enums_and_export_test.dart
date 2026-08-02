import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/presentation/services/tmc_excel_export_service.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';

void main() {
  group('TmcAccountingType', () {
    test('dbValue and displayName for individual', () {
      expect(TmcAccountingType.individual.dbValue, 'individual');
      expect(TmcAccountingType.individual.displayName, 'Индивидуальный');
    });

    test('dbValue and displayName for quantitative', () {
      expect(TmcAccountingType.quantitative.dbValue, 'quantitative');
      expect(TmcAccountingType.quantitative.displayName, 'Количественный');
    });
  });

  group('TmcUnitStatus', () {
    test('maps write-off and issue statuses', () {
      expect(TmcUnitStatus.writtenOff.dbValue, 'written_off');
      expect(TmcUnitStatus.issued.dbValue, 'issued');
      expect(TmcUnitStatus.inRepair.displayName, isNotEmpty);
    });
  });

  group('TmcOperationType', () {
    test('covers MVP operation codes', () {
      final codes = TmcOperationType.values.map((e) => e.dbValue).toSet();
      expect(codes.contains('receipt'), isTrue);
      expect(codes.contains('issue'), isTrue);
      expect(codes.contains('return_from_employee'), isTrue);
      expect(codes.contains('write_off'), isTrue);
      expect(codes.contains('send_to_repair'), isTrue);
      expect(codes.contains('correction'), isTrue);
    });
  });

  group('TmcExcelExportService', () {
    test('exportItems produces non-empty xlsx bytes', () {
      const service = TmcExcelExportService();
      final bytes = service.exportItems(const [
        TmcItem(
          id: '1',
          companyId: 'c1',
          name: 'Перфоратор',
          accountingType: TmcAccountingType.individual,
          unitOfMeasure: 'шт',
          status: TmcItemStatus.active,
          unitPrice: 1000,
          quantity: 2,
          totalCost: 2000,
          vatAmount: 0,
        ),
      ]);
      expect(bytes.isNotEmpty, isTrue);
      // XLSX zip signature
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
    });

    test('exportItems without cost still works', () {
      const service = TmcExcelExportService();
      final bytes = service.exportItems(const [], includeCost: false);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
