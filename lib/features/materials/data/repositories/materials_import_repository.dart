import 'package:projectgt/core/utils/formatters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../parsers/receipts_remote_parser.dart';

/// Репозиторий импорта накладных через Supabase Edge Functions.
class MaterialsImportRepository {
  final SupabaseClient _client;

  /// Создаёт репозиторий импорта с указанным [SupabaseClient].
  MaterialsImportRepository(this._client);

  /// Импорт на сервере через Edge Function `receipts_import` с возвратом summary.
  Future<Map<String, dynamic>> importViaServer({
    required List<ReceiptParseResult> results,
    required String companyId,
  }) async {
    final files = <Map<String, dynamic>>[];
    for (final r in results) {
      if (r.error != null) continue;
      final rn = (r.receiptNumber ?? '').trim();
      final rd = r.receiptDate;
      final cn = r.contractNumber;
      if (rn.isEmpty || rd == null) continue;
      final dateStr = GtFormatters.formatDateForApi(rd);
      files.add({
        'fileName': r.fileName,
        'receiptNumber': rn,
        'receiptDate': dateStr,
        'contractNumber': cn,
        'items': r.items
            .map((it) => {
                  'name': it.name,
                  'unit': it.unit,
                  'quantity': it.quantity,
                  'price': it.price,
                  'total': it.total,
                })
            .toList(),
      });
    }
    final res = await _client.functions.invoke('receipts_import', body: {
      'files': files,
      'companyId': companyId,
    }, headers: {
      'Content-Type': 'application/json',
    });
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Неверный ответ сервера');
  }

  // Локальный путь импорта больше не используется (перенесено на Edge Function).
}
