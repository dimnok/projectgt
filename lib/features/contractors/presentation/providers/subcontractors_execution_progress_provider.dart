import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contractor_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_object_provider.dart';

/// Фактическое выполнение подрядчика по одной позиции сметы.
@immutable
class SubcontractorExecutionProgress {
  /// Создаёт агрегированное выполнение.
  const SubcontractorExecutionProgress({
    required this.completedQuantity,
    required this.rowsCount,
  });

  /// Сумма фактического количества из закрытых отчётов работ.
  final double completedQuantity;

  /// Количество строк `work_items`, попавших в агрегат.
  final int rowsCount;
}

/// Факт выполнения выбранного подрядчика по выбранному объекту.
///
/// Ключ карты — `estimate_id`. Источник факта — закрытые смены (`works.status =
/// closed`) и строки работ с выбранным `contractor_id`.
final subcontractorsExecutionProgressProvider =
    FutureProvider.autoDispose<Map<String, SubcontractorExecutionProgress>>((
      ref,
    ) async {
      final companyId = ref.watch(activeCompanyIdProvider);
      final objectId = ref.watch(subcontractorsSelectedObjectIdProvider);
      final contractorId = ref.watch(
        subcontractorsSelectedContractorIdProvider,
      );

      if (companyId == null ||
          companyId.isEmpty ||
          objectId == null ||
          objectId.isEmpty ||
          contractorId == null ||
          contractorId.isEmpty) {
        return const <String, SubcontractorExecutionProgress>{};
      }

      final client = ref.watch(supabaseClientProvider);
      final response = await client
          .from('work_items')
          .select('estimate_id, quantity, works!inner(object_id, status)')
          .eq('company_id', companyId)
          .eq('contractor_id', contractorId)
          .eq('works.object_id', objectId)
          .eq('works.status', 'closed');

      final quantities = <String, double>{};
      final counts = <String, int>{};
      for (final raw in response as List<dynamic>) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }
        final estimateId = raw['estimate_id'] as String?;
        if (estimateId == null || estimateId.isEmpty) {
          continue;
        }
        final quantity = raw['quantity'];
        final value = quantity is num
            ? quantity.toDouble()
            : double.tryParse('$quantity') ?? 0;
        quantities.update(
          estimateId,
          (current) => current + value,
          ifAbsent: () => value,
        );
        counts.update(estimateId, (current) => current + 1, ifAbsent: () => 1);
      }

      return {
        for (final entry in quantities.entries)
          entry.key: SubcontractorExecutionProgress(
            completedQuantity: entry.value,
            rowsCount: counts[entry.key] ?? 0,
          ),
      };
    });
