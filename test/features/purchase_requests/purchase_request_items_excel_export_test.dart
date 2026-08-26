import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_items_excel_export.dart';

void main() {
  group('PurchaseRequestItemsExcelExportService', () {
    test('fileNameFor sanitizes request number', () {
      expect(
        PurchaseRequestItemsExcelExportService.fileNameFor('ЗП-2026-00001'),
        'Заявка_ЗП-2026-00001.xlsx',
      );
      expect(
        PurchaseRequestItemsExcelExportService.fileNameFor('  a/b:c  '),
        'Заявка_a_b_c.xlsx',
      );
      expect(
        PurchaseRequestItemsExcelExportService.fileNameFor('   '),
        'Заявка_заявка.xlsx',
      );
    });

    test('exportItems produces non-empty xlsx bytes', () {
      const service = PurchaseRequestItemsExcelExportService();
      final bytes = service.exportItems(const [
        PurchaseRequestItem(
          id: '1',
          requestId: 'r1',
          name: 'Кабель ВВГ',
          quantity: 12.5,
          unit: 'м',
          article: 'ART-1',
        ),
      ]);
      expect(bytes.isNotEmpty, isTrue);
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
    });

    test('exportItems works with empty list', () {
      const service = PurchaseRequestItemsExcelExportService();
      final bytes = service.exportItems(const []);
      expect(bytes.isNotEmpty, isTrue);
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
    });
  });
}
