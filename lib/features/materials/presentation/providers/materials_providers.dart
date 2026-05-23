import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/materials_repository.dart';
import '../../data/models/material_item.dart';
import '../../data/models/grouped_material_item.dart';
import '../../data/models/material_binding_model.dart';
import '../../../../core/di/providers.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';

/// Провайдер режима группировки по смете (для режима M15)
final isMaterialsGroupedProvider = StateProvider<bool>((ref) => false);

/// Провайдер репозитория материалов
final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MaterialsRepository(client);
});

/// Номер договора для фильтрации материалов.
///
/// Синхронизируется с [selectedMaterialsContractIdProvider]
/// через [MaterialsContractFilterField].
final selectedContractNumberProvider = StateProvider<String?>((ref) => null);

/// Провайдер списка материалов с учётом выбранного договора
final materialsListProvider = FutureProvider<List<MaterialItem>>((ref) async {
  final repo = ref.watch(materialsRepositoryProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  if (activeId == null) return [];

  final contractNumber = ref.watch(selectedContractNumberProvider);
  if (contractNumber == null || contractNumber.trim().isEmpty) {
    return [];
  }
  return repo.fetchAll(companyId: activeId, contractNumber: contractNumber);
});

/// Провайдер сгруппированных материалов
final materialsGroupedListProvider = FutureProvider<List<GroupedMaterialItem>>((
  ref,
) async {
  final repo = ref.watch(materialsRepositoryProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  if (activeId == null) return [];

  final contractNumber = ref.watch(selectedContractNumberProvider);
  if (contractNumber == null || contractNumber.trim().isEmpty) {
    return [];
  }
  return repo.fetchGrouped(companyId: activeId, contractNumber: contractNumber);
});

/// Провайдер списка номеров договоров (из таблицы materials)
final materialsContractNumbersProvider = FutureProvider<List<String>>((
  ref,
) async {
  final repo = ref.watch(materialsRepositoryProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  if (activeId == null) return [];

  return repo.fetchDistinctContractNumbers(companyId: activeId);
});

/// Фильтры по колонкам для таблицы материалов
final materialsColumnFiltersProvider = StateProvider<Map<String, String>>(
  (ref) => {},
);

/// Провайдер уникальных названий материалов из накладных.
final uniqueMaterialNamesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, contractNumber) async {
      final repo = ref.watch(materialsRepositoryProvider);
      final activeId = ref.watch(activeCompanyIdProvider);
      if (activeId == null) return [];

      return repo.fetchUniqueMaterialNames(
        companyId: activeId,
        contractNumber: contractNumber,
      );
    });

/// Провайдер материалов со статусом привязки.
final materialBindingListProvider = FutureProvider.autoDispose
    .family<
      List<MaterialBindingModel>,
      ({String? contractNumber, String estimateId})
    >((ref, arg) async {
      final repo = ref.watch(materialsRepositoryProvider);
      final activeId = ref.watch(activeCompanyIdProvider);
      if (activeId == null || arg.contractNumber == null) return [];

      return repo.fetchMaterialsWithBindingStatus(
        companyId: activeId,
        contractNumber: arg.contractNumber!,
        currentEstimateId: arg.estimateId,
      );
    });

/// Провайдер материалов, привязанных к конкретной сметной позиции.
final linkedMaterialsProvider = FutureProvider.autoDispose
    .family<List<MaterialItem>, String>((ref, estimateId) async {
      final repo = ref.watch(materialsRepositoryProvider);
      final activeId = ref.watch(activeCompanyIdProvider);
      if (activeId == null) return [];

      return repo.fetchLinkedMaterials(
        estimateId: estimateId,
        companyId: activeId,
      );
    });

/// Счётчик для принудительного обновления [estimateLinkedMaterialTooltipsMapProvider]
/// после привязки/отвязки материала (тот же источник, что «Детали позиции»).
final estimateLinkedMaterialTooltipsRefreshProvider = StateProvider<int>(
  (ref) => 0,
);

/// Карта [Estimate.id] → текст тултипа для таблицы сметы.
///
/// Данные совпадают с диалогом «Детали позиции»: для каждой позиции вызывается
/// [MaterialsRepository.fetchLinkedMaterials] (RPC `get_linked_materials_details`),
/// а не представление `v_materials_with_usage` (там неполная картина привязок).
final estimateLinkedMaterialTooltipsMapProvider = FutureProvider.autoDispose
    .family<
      Map<String, String>,
      ({String companyId, String contractNumber, String estimateIdsKey})
    >((ref, arg) async {
      ref.watch(estimateLinkedMaterialTooltipsRefreshProvider);
      final contract = arg.contractNumber.trim();
      if (arg.companyId.isEmpty || contract.isEmpty || arg.estimateIdsKey.isEmpty) {
        return {};
      }

      final repo = ref.watch(materialsRepositoryProvider);
      final ids = arg.estimateIdsKey.split(',').where((e) => e.isNotEmpty).toList();

      final map = <String, String>{};
      const chunkSize = 8;
      for (var i = 0; i < ids.length; i += chunkSize) {
        final chunk = ids.sublist(i, math.min(i + chunkSize, ids.length));
        await Future.wait(chunk.map((id) async {
          final list = await repo.fetchLinkedMaterials(
            estimateId: id,
            companyId: arg.companyId,
          );
          if (list.isEmpty) return;
          final lines = <String>{};
          for (final m in list) {
            lines.add(_linkedMaterialTooltipLine(m));
          }
          map[id] = _finalizeLinkedMaterialTooltipText(lines);
        }));
      }
      return map;
    });

String _linkedMaterialTooltipLine(MaterialItem m) {
  final name = m.name.trim();
  final receipt = m.receiptNumber?.trim();
  if (receipt != null && receipt.isNotEmpty) {
    return '$name · накладная $receipt';
  }
  return name.isEmpty ? 'Материал без наименования' : name;
}

String _finalizeLinkedMaterialTooltipText(Set<String> lines) {
  const maxLines = 100;
  final sorted = lines.toList()..sort();
  if (sorted.isEmpty) return '';
  if (sorted.length <= maxLines) {
    return sorted.join('\n');
  }
  final head = sorted.take(maxLines).join('\n');
  final rest = sorted.length - maxLines;
  return '$head\n… и ещё $rest';
}
