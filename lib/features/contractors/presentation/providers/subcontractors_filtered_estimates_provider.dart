import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_estimate_name_search_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contract_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_object_provider.dart';

/// Позиции смет ([Estimate]) по выбранному объекту и договору.
///
/// Данные из [estimateNotifierProvider]; фильтр [subcontractorsSelectedObjectIdProvider]
/// и [subcontractorsSelectedContractIdProvider]. Без объекта или договора список пуст.
final subcontractorsFilteredEstimatesProvider = Provider<List<Estimate>>((ref) {
  final objectId = ref.watch(subcontractorsSelectedObjectIdProvider);
  final contractId = ref.watch(subcontractorsSelectedContractIdProvider);
  final searchQuery = ref.watch(subcontractorsEstimateNameSearchProvider);
  final estimates = ref.watch(estimateNotifierProvider).estimates;
  if (objectId == null ||
      objectId.isEmpty ||
      contractId == null ||
      contractId.isEmpty) {
    return const [];
  }
  final query = searchQuery.trim().toLowerCase();
  final filtered = estimates
      .where(
        (e) =>
            e.objectId == objectId &&
            e.contractId != null &&
            e.contractId == contractId,
      )
      .toList();

  if (query.isEmpty) return filtered;

  return filtered.where((e) => e.name.toLowerCase().contains(query)).toList();
});
