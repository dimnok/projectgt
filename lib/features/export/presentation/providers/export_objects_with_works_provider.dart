import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

/// ID объектов, по которым есть смены — загружается один раз на сессию модуля.
///
/// [ref.keepAlive] + префетч в [ExportScreen] при входе в «Выгрузку».
final objectsWithWorksProvider = FutureProvider<Set<String>>((ref) async {
  final companyId = ref.watch(activeCompanyIdProvider);
  if (companyId == null || companyId.isEmpty) {
    return {};
  }

  ref.keepAlive();

  final client = ref.watch(supabaseClientProvider);
  final response = await client.rpc(
    'get_distinct_work_object_ids',
    params: {'p_company_id': companyId},
  );

  final rows = response as List<dynamic>;
  return rows
      .map((row) {
        if (row is Map) {
          return row['object_id'] as String?;
        }
        return row as String?;
      })
      .whereType<String>()
      .toSet();
});
